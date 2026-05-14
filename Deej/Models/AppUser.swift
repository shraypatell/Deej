//
//  AppUser.swift
//  Named AppUser to avoid colliding with Supabase's `User` type.
//

import Foundation

struct AppUser: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    var username: String
    var displayName: String?
    var bio: String?
    var avatarURL: URL?
    var location: String?
    var onboardingCompleted: Bool
    var tasteVector: TasteVector?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName        = "display_name"
        case bio
        case avatarURL          = "avatar_url"
        case location
        case onboardingCompleted = "onboarding_completed"
        case tasteVector         = "taste_vector"
        case createdAt           = "created_at"
    }
}
