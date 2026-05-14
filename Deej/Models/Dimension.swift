//
//  Dimension.swift
//  The 7 rating dimensions. LOCKED — see PLAN.md §4.
//

import Foundation

enum Dimension: String, CaseIterable, Codable, Sendable, Hashable {
    case artistPerformance = "artist_performance"
    case crowdEnergy       = "crowd_energy"
    case venue
    case lightingVisuals   = "lighting_visuals"
    case musicSelection    = "music_selection"
    case atmosphereVibe    = "atmosphere_vibe"
    case value

    /// User-visible label (rendered uppercase + underscored in the hardware UI).
    var displayLabel: String {
        switch self {
        case .artistPerformance: "ARTIST_PERFORMANCE"
        case .crowdEnergy:       "CROWD_ENERGY"
        case .venue:             "VENUE"
        case .lightingVisuals:   "LIGHTING/VISUALS"
        case .musicSelection:    "MUSIC_SELECTION"
        case .atmosphereVibe:    "ATMOSPHERE/VIBE"
        case .value:             "VALUE"
        }
    }

    /// Default ordering used in the ranking screen and the taste-profile bars.
    static var rankingOrder: [Dimension] {
        [.artistPerformance, .crowdEnergy, .venue, .lightingVisuals,
         .musicSelection, .atmosphereVibe, .value]
    }
}
