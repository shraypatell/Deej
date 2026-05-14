//
//  RootView.swift
//  Routes between Onboarding and the main tab bar based on app state.
//

import SwiftUI

@MainActor
@Observable
final class AppState {
    var hasCompletedOnboarding: Bool = false
    var selectedTab: AppTab = .feed
}

enum AppTab: Hashable {
    case feed, discover, log, attended, me
}

struct RootView: View {
    @State private var state = AppState()

    var body: some View {
        Group {
            if state.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(onComplete: {
                    state.hasCompletedOnboarding = true
                })
            }
        }
        .environment(state)
        .background(Color.deejBgCanvas.ignoresSafeArea())
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var s = state
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.deejBgCanvas.ignoresSafeArea())

            HardwareTabBar(selection: $s.selectedTab)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch state.selectedTab {
        case .feed:     FeedView()
        case .discover: DiscoverView()
        case .log:      LogStubView()
        case .attended: AttendedView()
        case .me:       ProfileView()
        }
    }
}

/// Temporary placeholder while the log/ranking flow is wired up in Phase 4.
private struct LogStubView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("LOG_NEW")
                .font(.deejMono(28, weight: .bold))
                .foregroundStyle(.deejCream)
            Text("ranking flow lands in phase 4")
                .font(.deejMono(11))
                .foregroundStyle(.deejOrangeLow)
                .deejTracking(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
