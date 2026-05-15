//
//  Friendship.swift
//  Mutual-friend social model. A row is created when one user (requester)
//  sends a friend request to another (recipient); status flips to .accepted
//  when the recipient accepts.
//

import Foundation

struct Friendship: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let requesterId: UUID
    let recipientId: UUID
    var status: Status
    let createdAt: Date
    var updatedAt: Date

    enum Status: String, Codable, Sendable, Hashable {
        case pending, accepted, blocked
    }

    enum CodingKeys: String, CodingKey {
        case id, status
        case requesterId = "requester_id"
        case recipientId = "recipient_id"
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }

    /// The "other side" of the friendship from the given perspective.
    func otherUserId(notMe selfId: UUID) -> UUID {
        requesterId == selfId ? recipientId : requesterId
    }
}
