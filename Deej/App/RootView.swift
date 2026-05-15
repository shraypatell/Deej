//
//  RootView.swift
//  Routes between a boot screen, Onboarding, and the tab bar based on the
//  current user's Supabase profile.
//

import SwiftUI

@MainActor
@Observable
final class AppState {
    var selectedTab: AppTab = .feed
}

enum AppTab: Hashable {
    case feed, discover, log, attended, me
}

struct RootView: View {
    @Environment(AppServices.self) private var services
    @State private var state = AppState()

    var body: some View {
        Group {
            if services.currentUser == nil {
                BootView()
            } else if services.currentUser?.onboardingCompleted == true {
                MainTabView()
            } else {
                OnboardingView { Task { await services.markOnboardingComplete() } }
            }
        }
        .environment(state)
        .background(Color.deejBgCanvas.ignoresSafeArea())
    }
}

private struct BootView: View {
    @Environment(AppServices.self) private var services

    var body: some View {
        VStack(spacing: 16) {
            StatusLED(state: .pending, pulses: true)
                .scaleEffect(2)
                .padding(.bottom, 8)
            Text("DEEJ.SYS")
                .font(.deejMono(20, weight: .bold))
                .foregroundStyle(.deejCream)
                .deejTracking(2)
            Text("BOOTING · CONNECTING_TO_CLOUD")
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(.deejOrangeLow)
                .deejTracking(1.5)
            if let err = services.lastError {
                VStack(spacing: 4) {
                    Text("BOOT_ERROR")
                        .font(.deejMono(9, weight: .bold))
                        .foregroundStyle(.deejStatusRed)
                        .deejTracking(1.5)
                    Text(err)
                        .font(.deejMono(8))
                        .foregroundStyle(.deejOrangeLow)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 14)

                Button("RETRY") {
                    Task { await services.bootstrap() }
                }
                .buttonStyle(.hardware(.secondary))
                .font(.deejMono(11, weight: .bold))
                .deejTracking(2)
                .frame(width: 160)
                .padding(.top, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

private struct LogStubView: View {
    @Environment(AppServices.self) private var services
    @State private var rankingEvent: Event?

    var body: some View {
        VStack(spacing: 14) {
            Text("LOG_NEW")
                .font(.deejMono(28, weight: .bold))
                .foregroundStyle(.deejCream)
            Text("pick a recent event to rate")
                .font(.deejMono(11))
                .foregroundStyle(.deejOrangeLow)
                .deejTracking(1)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(services.suggestedEvents) { event in
                        Button { rankingEvent = event } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.artistName)
                                        .font(.deejMono(14, weight: .semibold))
                                        .foregroundStyle(.deejCream)
                                    Text("\(event.venueName) · \(shortDate(event.eventDate))")
                                        .font(.deejMono(9))
                                        .foregroundStyle(.deejOrangeLow)
                                }
                                Spacer()
                                Text("▸")
                                    .font(.deejMono(14, weight: .bold))
                                    .foregroundStyle(.deejOrangeMid)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Rectangle().fill(Color.deejOrangeTrack).frame(height: 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 30)
        .padding(.bottom, 130)
        .sheet(item: $rankingEvent) { event in
            EventRankingView(event: event)
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.deejBgCanvas)
        }
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd · EEE HH:mm"
        return f.string(from: date).uppercased()
    }
}

#Preview {
    RootView()
        .environment(AppServices())
        .preferredColorScheme(.dark)
}
