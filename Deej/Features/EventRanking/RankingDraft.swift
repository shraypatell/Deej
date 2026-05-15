//
//  RankingDraft.swift
//  Mutable in-progress rating state for the EventRanking screen.
//  Holds the 7 dimension ratings, the focused dimension, and the notes string.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class RankingDraft {
    let event: Event
    private(set) var ratings: [Dimension: Int]
    var focusedDimension: Dimension = .artistPerformance
    var notes: String = ""

    init(event: Event, defaultRating: Int = 5) {
        self.event = event
        var seed: [Dimension: Int] = [:]
        for d in Dimension.allCases { seed[d] = defaultRating }
        self.ratings = seed
    }

    func value(for dim: Dimension) -> Int {
        ratings[dim] ?? 5
    }

    func setValue(_ newValue: Int, for dim: Dimension) {
        ratings[dim] = newValue
    }

    /// Binding for the focused dimension — used to drive the rotary knob.
    var focusedBinding: Binding<Int> {
        Binding(
            get: { [self] in value(for: focusedDimension) },
            set: { [self] in setValue($0, for: focusedDimension) }
        )
    }

    func binding(for dim: Dimension) -> Binding<Int> {
        Binding(
            get: { [self] in value(for: dim) },
            set: { [self] in setValue($0, for: dim) }
        )
    }

    var aggregateScore: Double {
        EventLog.aggregate(ratings)
    }

    /// Snapshot the draft into a persistable EventLog for the given user.
    func toEventLog(userId: UUID) -> EventLog {
        EventLog(
            id: UUID(),
            userId: userId,
            eventId: event.id,
            ratingArtistPerformance: value(for: .artistPerformance),
            ratingCrowdEnergy:       value(for: .crowdEnergy),
            ratingVenue:             value(for: .venue),
            ratingLightingVisuals:   value(for: .lightingVisuals),
            ratingMusicSelection:    value(for: .musicSelection),
            ratingAtmosphereVibe:    value(for: .atmosphereVibe),
            ratingValue:             value(for: .value),
            aggregateScore:          aggregateScore,
            notes:                   notes.isEmpty ? nil : notes,
            photoURLs:               [],
            status:                  .active,
            createdAt:               .now,
            updatedAt:               .now
        )
    }
}
