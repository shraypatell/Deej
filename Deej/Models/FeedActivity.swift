//
//  FeedActivity.swift
//  One row in `public.activity_feed`. Rendered as a card in FeedView.
//

import Foundation

struct FeedActivity: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let type: ActivityType
    let subjectEventId: UUID?
    let subjectUserId: UUID?
    let metadata: ActivityMetadata
    let createdAt: Date

    enum ActivityType: String, Codable, Sendable, Hashable {
        case ratedEvent   = "rated_event"
        case goingToEvent = "going_to_event"
        case milestone
        case addedToWant  = "added_to_want"
        case friendJoined = "friend_joined"
    }

    enum CodingKeys: String, CodingKey {
        case id, type, metadata
        case userId         = "user_id"
        case subjectEventId = "subject_event_id"
        case subjectUserId  = "subject_user_id"
        case createdAt      = "created_at"
    }
}

/// Loose-typed JSONB metadata. Each ActivityType only uses a subset of fields.
struct ActivityMetadata: Codable, Sendable, Hashable {
    var score: Double?
    var badge: String?
    var blurb: String?
}
