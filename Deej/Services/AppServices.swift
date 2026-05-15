//
//  AppServices.swift
//  Top-level @Observable that owns the Supabase-backed app state.
//  Replaces LocalEventStore as the source of truth. Anonymous auth on first
//  launch creates a `users` row; subsequent launches resume the session.
//
//  v0 uses anonymous auth so we can ship without setting up Sign in with Apple.
//  Phase 8 polish swaps to SIWA via auth.linkIdentity(...).
//

import Foundation
import OSLog
import Supabase

private let log = Logger(subsystem: "com.shray.deej", category: "AppServices")

@MainActor
@Observable
final class AppServices {
    private let client = DeejSupabase.shared

    private(set) var currentUser: AppUser?
    private(set) var events: [Event] = []
    private(set) var logs: [EventLog] = []
    private(set) var friendships: [Friendship] = []
    private(set) var friendUsers: [UUID: AppUser] = [:]   // friend id → profile
    private(set) var feedActivities: [FeedActivity] = []
    private(set) var activityActorUsers: [UUID: AppUser] = [:] // user_id → profile
    private(set) var activityEvents: [UUID: Event] = [:]       // event_id → event
    private(set) var activityLogs: [UUID: EventLog] = [:]      // (event_id, actor) → log
    private(set) var isBootstrapping: Bool = false
    private(set) var lastError: String?

    // MARK: derived state (mirrors LocalEventStore's API)
    var suggestedEvents: [Event] {
        events.sorted { $0.eventDate > $1.eventDate }
    }

    var orderedLogs: [EventLog] {
        logs.sorted { $0.createdAt > $1.createdAt }
    }

    var bestCapture: EventLog? {
        logs.max { $0.aggregateScore < $1.aggregateScore }
    }

    func event(byId id: UUID) -> Event? {
        events.first { $0.id == id }
    }

    var acceptedFriendships: [Friendship] {
        friendships.filter { $0.status == .accepted }
    }

    var pendingIncomingFriendships: [Friendship] {
        guard let me = currentUser?.id else { return [] }
        return friendships.filter { $0.status == .pending && $0.recipientId == me }
    }

    var pendingOutgoingFriendships: [Friendship] {
        guard let me = currentUser?.id else { return [] }
        return friendships.filter { $0.status == .pending && $0.requesterId == me }
    }

    func friend(_ friendship: Friendship) -> AppUser? {
        guard let me = currentUser?.id else { return nil }
        return friendUsers[friendship.otherUserId(notMe: me)]
    }

    /// Stable user id for views that previously used `LocalEventStore.mockUserId`.
    var userId: UUID {
        currentUser?.id ?? UUID()
    }

    // MARK: recommendation algorithm (Phase 7)
    /// User's live taste vector computed from their logged events.
    var tasteVector: TasteVector {
        logs.reduce(TasteVector.empty) { $0.adding($1) }
    }

    /// Average rating profile for an event across all logs visible to the user.
    /// v0: only this user's logs are visible (single-user). v0.1: friend logs
    /// become visible via RLS once friendships exist; we just include those
    /// here too. Production would back this with a `event_rating_profiles`
    /// materialized view on Postgres.
    func eventTasteProfile(_ eventId: UUID) -> TasteVector? {
        let relevant = logs.filter { $0.eventId == eventId }
        guard !relevant.isEmpty else { return nil }
        return relevant.reduce(TasteVector.empty) { $0.adding($1) }
    }

    /// Hybrid recommendation score in [0, 1].
    /// score = α·tasteMatch + β·friendSignal + γ·collabSignal
    /// Phase 7 implements taste match; friend + collab roll in over time.
    func recommendationScore(for event: Event) -> Double {
        let alpha = 0.5, beta = 0.3, gamma = 0.2
        return alpha * tasteMatch(for: event)
             + beta  * friendSignal(for: event)
             + gamma * collabSignal(for: event)
    }

    /// 0...1, falls back to 0 when the user has no logs to build a taste vector.
    private func tasteMatch(for event: Event) -> Double {
        let user = tasteVector
        guard user.sampleSize >= 1 else { return 0 }
        guard let eventVec = eventTasteProfile(event.id) else {
            // Unknown event → neutral 5/10 baseline, dampened.
            var seed: [Dimension: Double] = [:]
            for d in Dimension.allCases { seed[d] = 5.0 }
            let neutral = TasteVector(averages: seed, sampleSize: 1, computedAt: .now)
            return user.cosineSimilarity(to: neutral) * 0.4
        }
        return user.cosineSimilarity(to: eventVec)
    }

    private func friendSignal(for event: Event) -> Double {
        // Friend ratings live in `logs` too once friendships are accepted (RLS
        // surfaces them). For the v0 single-user case this is just 0.
        // Production: weight by recency, mean across friend ratings 1..10
        // normalized to 0..1.
        return 0
    }

    private func collabSignal(for event: Event) -> Double {
        // Item-item collaborative filtering requires a corpus-wide query. v0
        // returns 0; v0.1 wires this in once the dataset is non-trivial.
        return 0
    }

    /// Events sorted by recommendation score (highest first). Events with
    /// score == 0 are still included at the bottom.
    var recommendedEvents: [Event] {
        events
            .map { ($0, recommendationScore(for: $0)) }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    // MARK: bootstrap
    /// Idempotent: safe to call multiple times.
    func bootstrap() async {
        guard !isBootstrapping, currentUser == nil else { return }
        isBootstrapping = true
        defer { isBootstrapping = false }

        do {
            try await ensureSession()
            try await ensureUserRow()
            try await fetchEvents()
            try await seedDemoEventsIfEmpty()
            try await fetchLogs()
            try await fetchFriendships()
            try await fetchActivityFeed()
        } catch {
            recordError(error, op: "bootstrap")
        }
    }

    func refreshActivityFeed() async {
        do { try await fetchActivityFeed() }
        catch { recordError(error, op: "refresh_feed") }
    }

    private func fetchActivityFeed() async throws {
        // RLS already filters to self + accepted friends, so a plain select works.
        let activities: [FeedActivity] = try await client.from("activity_feed")
            .select()
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value
        log.info("fetchActivityFeed: count=\(activities.count)")
        feedActivities = activities

        // Hydrate referenced events + actors so the cards can render.
        let eventIds = Set(activities.compactMap { $0.subjectEventId })
            .subtracting(activityEvents.keys)
        let actorIds = Set(activities.map { $0.userId })
            .subtracting(activityActorUsers.keys)
            .subtracting(currentUser.map { Set([$0.id]) } ?? [])

        if !eventIds.isEmpty {
            let fetched: [Event] = try await client.from("events")
                .select()
                .in("id", values: eventIds.map { $0.uuidString })
                .execute()
                .value
            for e in fetched { activityEvents[e.id] = e }
        }
        if !actorIds.isEmpty {
            let users: [AppUser] = try await client.from("users")
                .select()
                .in("id", values: actorIds.map { $0.uuidString })
                .execute()
                .value
            for u in users { activityActorUsers[u.id] = u }
        }
    }

    /// Look up the actor's profile, falling back to currentUser for the
    /// "my own activity" case.
    func actor(for activity: FeedActivity) -> AppUser? {
        if activity.userId == currentUser?.id { return currentUser }
        return activityActorUsers[activity.userId] ?? friendUsers[activity.userId]
    }

    func activityEvent(for activity: FeedActivity) -> Event? {
        guard let eid = activity.subjectEventId else { return nil }
        return activityEvents[eid] ?? event(byId: eid)
    }

    // MARK: writes
    func save(_ log: EventLog) async {
        do {
            try await client.from("event_logs")
                .upsert(log)
                .execute()
            try await fetchLogs()
        } catch {
            recordError(error, op: "save_log")
        }
    }

    // MARK: friend operations
    func refreshFriends() async {
        do { try await fetchFriendships() }
        catch { recordError(error, op: "refresh_friends") }
    }

    func searchUsers(matching query: String) async -> [AppUser] {
        guard query.count >= 2 else { return [] }
        let q = query.lowercased()
        do {
            let result: [AppUser] = try await client.from("users")
                .select()
                .ilike("username", pattern: "%\(q)%")
                .neq("id", value: currentUser?.id.uuidString ?? "")
                .limit(20)
                .execute()
                .value
            return result
        } catch {
            recordError(error, op: "search_users")
            return []
        }
    }

    func sendFriendRequest(to userId: UUID) async {
        guard let me = currentUser?.id else { return }
        struct Payload: Encodable {
            let requester_id: String
            let recipient_id: String
            let status: String
        }
        do {
            try await client.from("friendships")
                .insert(Payload(
                    requester_id: me.uuidString,
                    recipient_id: userId.uuidString,
                    status: "pending"))
                .execute()
            try await fetchFriendships()
        } catch {
            recordError(error, op: "send_friend_request")
        }
    }

    func acceptFriendRequest(_ friendship: Friendship) async {
        do {
            try await client.from("friendships")
                .update(["status": "accepted"])
                .eq("id", value: friendship.id)
                .execute()
            try await fetchFriendships()
        } catch {
            recordError(error, op: "accept_friend")
        }
    }

    func declineFriendRequest(_ friendship: Friendship) async {
        do {
            try await client.from("friendships")
                .delete()
                .eq("id", value: friendship.id)
                .execute()
            try await fetchFriendships()
        } catch {
            recordError(error, op: "decline_friend")
        }
    }

    private func fetchFriendships() async throws {
        guard let me = currentUser?.id else { return }
        let result: [Friendship] = try await client.from("friendships")
            .select()
            .or("requester_id.eq.\(me.uuidString),recipient_id.eq.\(me.uuidString)")
            .execute()
            .value
        log.info("fetchFriendships: count=\(result.count)")
        friendships = result

        // Load the user rows for every counterpart so we can render names/avatars.
        let otherIds = result
            .map { $0.otherUserId(notMe: me) }
            .filter { !friendUsers.keys.contains($0) }
        guard !otherIds.isEmpty else { return }
        let users: [AppUser] = try await client.from("users")
            .select()
            .in("id", values: otherIds.map { $0.uuidString })
            .execute()
            .value
        for u in users { friendUsers[u.id] = u }
    }

    // MARK: event creation (promotion)
    func createEvent(artistName: String,
                     venueName: String,
                     city: String?,
                     eventDate: Date,
                     startTime: Date?) async -> Event? {
        guard let me = currentUser?.id else { return nil }
        let payload = Event(
            id: UUID(),
            artistName: artistName,
            venueName: venueName,
            city: city?.isEmpty == true ? nil : city,
            eventDate: eventDate,
            startTime: startTime,
            promotedByUserId: me,
            createdAt: .now
        )
        do {
            try await client.from("events").insert(payload).execute()
            try await fetchEvents()
            return payload
        } catch {
            recordError(error, op: "create_event")
            return nil
        }
    }

    func markOnboardingComplete() async {
        guard var user = currentUser else { return }
        user.onboardingCompleted = true
        do {
            try await client.from("users")
                .update(["onboarding_completed": true])
                .eq("id", value: user.id)
                .execute()
            currentUser = user
        } catch {
            recordError(error, op: "mark_onboarded")
        }
    }

    // MARK: private — session + user
    private func ensureSession() async throws {
        if (try? await client.auth.session) != nil { return }
        _ = try await client.auth.signInAnonymously()
    }

    private func ensureUserRow() async throws {
        let session = try await client.auth.session
        let id = session.user.id

        // Try to fetch existing row first.
        if let existing: AppUser = try? await client.from("users")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value as AppUser {
            log.info(" ensureUserRow: existing user, onboarding=\(existing.onboardingCompleted)")
            currentUser = existing
            return
        }

        // Otherwise insert one. Use a column-explicit insert payload so we
        // never accidentally send Bool encoded as anything other than `false`.
        struct NewUserPayload: Encodable {
            let id: String
            let username: String
            let onboarding_completed: Bool
            let created_at: String
        }
        let payload = NewUserPayload(
            id: id.uuidString,
            username: "user_\(id.uuidString.prefix(6).lowercased())",
            onboarding_completed: false,
            created_at: ISO8601DateFormatter().string(from: .now)
        )
        log.info(" ensureUserRow: inserting payload onboarding=\(payload.onboarding_completed)")
        try await client.from("users").insert(payload).execute()
        // Refetch to get the canonical row (with server defaults applied).
        let inserted: AppUser = try await client.from("users")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        log.info(" ensureUserRow: after insert, onboarding=\(inserted.onboardingCompleted)")
        currentUser = inserted
    }

    // MARK: private — events
    private func fetchEvents() async throws {
        let result: [Event] = try await client.from("events")
            .select()
            .execute()
            .value
        log.info("fetchEvents: count=\(result.count)")
        events = result
    }

    /// First-run convenience: seed the canonical `events` table with demo
    /// concerts so Onboarding has something to suggest. No-op once data exists.
    private func seedDemoEventsIfEmpty() async throws {
        guard events.isEmpty else { return }
        let now = Date()
        let cal = Calendar.current
        let demo: [(String, String, String, Int)] = [
            ("@FLOATING_POINTS", "BROOKLYN_STEEL",   "BKLYN", -7),
            ("@JON_HOPKINS",     "THE_SULTAN_ROOM",  "BKLYN", -14),
            ("@PEGGY_GOU",       "PUBLIC_RECORDS",   "BKLYN", -21),
            ("@FRED_AGAIN",      "KNOCKDOWN_CENTER", "BKLYN", -28),
            ("@FOUR_TET",        "KNOCKDOWN_CENTER", "BKLYN", -45)
        ]
        let seed = demo.map { artist, venue, city, daysAgo -> Event in
            Event(
                id: UUID(),
                artistName: artist,
                venueName: venue,
                city: city,
                eventDate: cal.date(byAdding: .day, value: daysAgo, to: now) ?? now,
                startTime: nil,
                promotedByUserId: nil,
                createdAt: now
            )
        }
        try await client.from("events").insert(seed).execute()
        try await fetchEvents()
    }

    // MARK: private — logs
    private func fetchLogs() async throws {
        guard let user = currentUser else { return }
        let result: [EventLog] = try await client.from("event_logs")
            .select()
            .eq("user_id", value: user.id)
            .execute()
            .value
        log.info("fetchLogs: count=\(result.count)")
        logs = result
    }

    // MARK: errors
    private func recordError(_ error: Error, op: String) {
        let full = "\(error)"
        log.info(" \(op) failed: \(full)")
        lastError = "\(op.uppercased()) · \(shortMessage(from: full))"
    }

    /// Pulls a human-readable `message: "..."` substring out of the long
    /// Supabase Auth error description. Falls back to the raw string.
    private func shortMessage(from raw: String) -> String {
        guard let r = raw.range(of: "message: \""),
              let end = raw.range(of: "\"", range: r.upperBound..<raw.endIndex)
        else { return raw }
        return String(raw[r.upperBound..<end.lowerBound])
    }
}
