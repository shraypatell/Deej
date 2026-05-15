//
//  ActivityReaction.swift
//  One reaction (currently always a heart) on a FeedActivity.
//

import Foundation

struct ActivityReaction: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let activityId: UUID
    let userId: UUID
    let emoji: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, emoji
        case activityId = "activity_id"
        case userId     = "user_id"
        case createdAt  = "created_at"
    }
}
