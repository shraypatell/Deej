//
//  EventLog.swift
//  A user's rating of a canonical event.
//

import Foundation

struct EventLog: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let eventId: UUID
    var ratingArtistPerformance: Int
    var ratingCrowdEnergy: Int
    var ratingVenue: Int
    var ratingLightingVisuals: Int
    var ratingMusicSelection: Int
    var ratingAtmosphereVibe: Int
    var ratingValue: Int
    var aggregateScore: Double
    var notes: String?
    var photoURLs: [URL]
    var status: ArchiveStatus
    let createdAt: Date
    var updatedAt: Date

    enum ArchiveStatus: String, Codable, Sendable { case active, archived }

    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case userId                   = "user_id"
        case eventId                  = "event_id"
        case ratingArtistPerformance  = "rating_artist_performance"
        case ratingCrowdEnergy        = "rating_crowd_energy"
        case ratingVenue              = "rating_venue"
        case ratingLightingVisuals    = "rating_lighting_visuals"
        case ratingMusicSelection     = "rating_music_selection"
        case ratingAtmosphereVibe     = "rating_atmosphere_vibe"
        case ratingValue              = "rating_value"
        case aggregateScore           = "aggregate_score"
        case photoURLs                = "photo_urls"
        case createdAt                = "created_at"
        case updatedAt                = "updated_at"
    }

    /// Map of dimension → rating, for ergonomic code (UI loops, taste vector math).
    var dimensionRatings: [Dimension: Int] {
        [
            .artistPerformance: ratingArtistPerformance,
            .crowdEnergy:       ratingCrowdEnergy,
            .venue:             ratingVenue,
            .lightingVisuals:   ratingLightingVisuals,
            .musicSelection:    ratingMusicSelection,
            .atmosphereVibe:    ratingAtmosphereVibe,
            .value:             ratingValue
        ]
    }

    /// Equal-weight mean of the 7 dimensions. Persisted to `aggregate_score`.
    static func aggregate(_ ratings: [Dimension: Int]) -> Double {
        let values = Dimension.allCases.compactMap { ratings[$0] }
        guard !values.isEmpty else { return 0 }
        return Double(values.reduce(0, +)) / Double(values.count)
    }
}
