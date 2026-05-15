//
//  SupabaseClient.swift
//  Single shared Supabase client, configured from Secrets.swift.
//
//  Phase 4: client is wired but app traffic still flows through LocalEventStore.
//  Phase 5+: services (AuthService, EventService, FriendService) talk through this.
//

import Foundation
import Supabase

enum DeejSupabase {
    /// Shared client. Created lazily on first access.
    /// Safe to call from any actor — `SupabaseClient` is internally thread-safe.
    static let shared: SupabaseClient = SupabaseClient(
        supabaseURL: Secrets.supabaseURL,
        supabaseKey: Secrets.supabaseAnonKey
    )
}
