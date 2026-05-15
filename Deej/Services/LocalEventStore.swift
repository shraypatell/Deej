//
//  LocalEventStore.swift
//  In-memory store of canonical Events and EventLogs.
//  Phase 4 backing for the app while Supabase wiring is in progress (Phase 4.8/4.9).
//  Once Supabase is in, this becomes a write-through cache or is replaced.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class LocalEventStore {
    private(set) var events: [UUID: Event] = [:]
    private(set) var logs: [EventLog] = []

    /// The "current user" placeholder until Sign in with Apple lands.
    let mockUserId: UUID = UUID()

    init(seedDemoData: Bool = true) {
        if seedDemoData { seedSuggestedEvents() }
    }

    // MARK: events
    var suggestedEvents: [Event] {
        Array(events.values).sorted { $0.eventDate > $1.eventDate }
    }

    func event(byId id: UUID) -> Event? { events[id] }

    /// Used by the OnboardingView to look up event by displayed artist name.
    func event(matchingArtist artist: String) -> Event? {
        events.values.first { $0.artistName == artist }
    }

    // MARK: logs
    var orderedLogs: [EventLog] {
        logs.sorted { $0.createdAt > $1.createdAt }
    }

    /// Highest-scoring log, used for the BEST_CAPTURE card on Attended.
    var bestCapture: EventLog? {
        logs.max { $0.aggregateScore < $1.aggregateScore }
    }

    func save(_ log: EventLog) {
        if let i = logs.firstIndex(where: { $0.id == log.id }) {
            logs[i] = log
        } else {
            logs.append(log)
        }
    }

    func log(forEvent eventId: UUID) -> EventLog? {
        logs.first { $0.eventId == eventId }
    }

    // MARK: seeding
    private func seedSuggestedEvents() {
        let now = Date()
        let cal = Calendar.current
        let demo: [(String, String, String, Int)] = [
            ("@FLOATING_POINTS", "BROOKLYN_STEEL",   "BKLYN", -7),
            ("@JON_HOPKINS",     "THE_SULTAN_ROOM",  "BKLYN", -14),
            ("@PEGGY_GOU",       "PUBLIC_RECORDS",   "BKLYN", -21),
            ("@FRED_AGAIN",      "KNOCKDOWN_CENTER", "BKLYN", -28),
            ("@FOUR_TET",        "KNOCKDOWN_CENTER", "BKLYN", -45)
        ]
        for (artist, venue, city, daysAgo) in demo {
            let date = cal.date(byAdding: .day, value: daysAgo, to: now) ?? now
            let event = Event(
                id: UUID(),
                artistName: artist,
                venueName: venue,
                city: city,
                eventDate: date,
                startTime: nil,
                promotedByUserId: nil,
                createdAt: now
            )
            events[event.id] = event
        }
    }
}
