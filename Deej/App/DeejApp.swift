//
//  DeejApp.swift
//  Deej — live music event tracker
//

import SwiftUI

@main
struct DeejApp: App {
    @State private var store = LocalEventStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
                .tint(.deejOrangePrimary)
        }
    }
}
