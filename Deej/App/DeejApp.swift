//
//  DeejApp.swift
//  Deej — live music event tracker
//

import SwiftUI

@main
struct DeejApp: App {
    @State private var services = AppServices()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(services)
                .preferredColorScheme(.dark)
                .tint(.deejOrangePrimary)
                .task { await services.bootstrap() }
        }
    }
}
