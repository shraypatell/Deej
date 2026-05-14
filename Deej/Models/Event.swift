//
//  Event.swift
//  Canonical event row, shared across users (fuzzy-matched on artist+venue+date).
//

import Foundation

struct Event: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    var artistName: String
    var venueName: String
    var city: String?
    var eventDate: Date
    var startTime: Date?
    var promotedByUserId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case artistName       = "artist_name"
        case venueName        = "venue_name"
        case city
        case eventDate        = "event_date"
        case startTime        = "start_time"
        case promotedByUserId = "promoted_by_user_id"
        case createdAt        = "created_at"
    }
}
