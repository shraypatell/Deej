//
//  DeejApp.swift
//  Deej — live music event tracker
//

import SwiftUI

@main
struct DeejApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(.deejOrangePrimary)
        }
    }
}
