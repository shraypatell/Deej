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

    /// Stable user id for views that previously used `LocalEventStore.mockUserId`.
    var userId: UUID {
        currentUser?.id ?? UUID()
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
        } catch {
            recordError(error, op: "bootstrap")
        }
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
