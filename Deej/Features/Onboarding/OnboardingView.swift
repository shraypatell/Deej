//
//  OnboardingView.swift
//  First-run flow. Boot status header → suggested events list → "rate one to unlock".
//  Phase 3: UI scaffold + tap-through that just flips `hasCompletedOnboarding`.
//  Phase 4 wires this to the real EventRanking flow.
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    private let suggestions: [SuggestedEvent] = [
        SuggestedEvent(artist: "@FLOATING_POINTS", venue: "BROOKLYN_STEEL",
                       dateLine: "2024.11.15 · FRI 22:00", isBestMatch: true),
        SuggestedEvent(artist: "@JON_HOPKINS",     venue: "THE_SULTAN_ROOM",
                       dateLine: "2024.11.08 · FRI 23:30", isBestMatch: false),
        SuggestedEvent(artist: "@PEGGY_GOU",       venue: "PUBLIC_RECORDS",
                       dateLine: "2024.10.25 · FRI 22:00", isBestMatch: false),
        SuggestedEvent(artist: "@FRED_AGAIN",      venue: "KNOCKDOWN_CENTER",
                       dateLine: "2024.10.18 · FRI 22:00", isBestMatch: false),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topRow
                bootStatus
                divider
                hero
                divider
                sectionHeader
                suggestionsList
                ctaBlock
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.deejBgCanvas.ignoresSafeArea())
    }

    // MARK: top engraving row
    private var topRow: some View {
        HStack {
            Text("DEEJ.SYS")
                .deejTracking(1.5)
            Spacer()
            Text("MOD-00 / FIRST_RUN")
                .deejTracking(1.5)
            StatusLED(state: .awaiting, pulses: true)
                .padding(.leading, 6)
        }
        .font(.deejMono(9, weight: .medium))
        .foregroundStyle(Color.deejEngraving)
        .padding(.top, 4)
    }

    // MARK: boot status lines
    private var bootStatus: some View {
        VStack(alignment: .leading, spacing: 4) {
            bootRow(state: .ok,       label: "AUDIO_ENGINE.READY", tail: "[OK]",        tailColor: .deejStatusGreen)
            bootRow(state: .ok,       label: "LOCATION.PERMISSION", tail: "[OK]",       tailColor: .deejStatusGreen)
            bootRow(state: .pending,  label: "USER_PROFILE",        tail: "[PENDING]",  tailColor: .deejLEDAmber)
            bootRow(state: .awaiting, label: "FIRST_RATING",        tail: "[AWAITING ▮]", tailColor: .deejStatusRed)
        }
        .padding(.top, 14)
    }

    private func bootRow(state: StatusLED.State, label: String, tail: String, tailColor: Color) -> some View {
        HStack(spacing: 8) {
            StatusLED(state: state, size: 4, pulses: state == .awaiting)
            Text(label)
                .font(.deejMono(9, weight: .medium))
                .foregroundStyle(Color.deejCreamDim)
                .deejTracking(1.2)
            Spacer()
            Text(tail)
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(tailColor)
                .deejTracking(1.2)
        }
    }

    // MARK: hero
    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Text("WELCOME")
                    .font(.deejMono(36, weight: .bold))
                    .foregroundStyle(Color.deejCream)
                Rectangle()
                    .fill(Color.deejOrangeHigh)
                    .frame(width: 16, height: 28)
                    .padding(.leading, 4)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("rate one show to initialize your profile.")
                    .font(.deejMono(11))
                    .foregroundStyle(Color.deejCreamDim)
                Text("the device learns your taste from this point on.")
                    .font(.deejMono(11))
                    .foregroundStyle(Color.deejOrangeLow)
            }
        }
        .padding(.vertical, 14)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.deejBgPanelEdge)
            .frame(height: 1)
            .padding(.top, 10)
    }

    // MARK: suggestions header
    private var sectionHeader: some View {
        HStack {
            Text("SELECT_FROM_NEARBY_RECENT")
                .deejTracking(1.5)
            Spacer()
            Text("\(suggestions.count) SUGGESTIONS")
                .deejTracking(1.2)
                .foregroundStyle(Color.deejOrangeLow)
        }
        .font(.deejMono(9, weight: .semibold))
        .foregroundStyle(Color.deejCreamDim)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    // MARK: list
    private var suggestionsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.offset) { _, event in
                Button { onComplete() } label: { row(for: event) }
                    .buttonStyle(.plain)
                Rectangle()
                    .fill(Color.deejOrangeTrack)
                    .frame(height: 1)
                    .padding(.leading, 16)
            }
        }
    }

    private func row(for event: SuggestedEvent) -> some View {
        HStack(spacing: 0) {
            // left stripe (only for best match)
            Rectangle()
                .fill(event.isBestMatch ? Color.deejOrangeBright : .clear)
                .frame(width: 3)
                .shadow(color: event.isBestMatch ? Color.deejOrangePrimary : .clear, radius: 6)

            VStack(alignment: .leading, spacing: 4) {
                if event.isBestMatch {
                    HStack {
                        Spacer()
                        Text("● BEST_MATCH")
                            .font(.deejMono(8, weight: .bold))
                            .foregroundStyle(Color.deejStatusGreen)
                            .deejTracking(1.2)
                    }
                }
                Text(event.artist)
                    .font(.deejMono(14, weight: event.isBestMatch ? .bold : .semibold))
                    .foregroundStyle(event.isBestMatch ? Color.deejCream : Color.deejOrangeMid)
                Text("\(event.venue) · \(event.dateLine)")
                    .font(.deejMono(8))
                    .foregroundStyle(Color.deejOrangeLow)
                    .deejTracking(0.8)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)

            Spacer(minLength: 0)

            Text("▸")
                .font(.deejMono(16, weight: .bold))
                .foregroundStyle(event.isBestMatch ? Color.deejStatusGreen : Color.deejOrangeLow)
                .padding(.trailing, 12)
        }
        .contentShape(Rectangle())
    }

    // MARK: bottom CTAs
    private var ctaBlock: some View {
        VStack(spacing: 14) {
            Text("didn't see your event in the list?")
                .font(.deejMono(10))
                .foregroundStyle(Color.deejOrangeLow)
                .padding(.top, 20)

            Button {
                onComplete()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                    Text("LOG_MANUALLY")
                        .font(.deejMono(13, weight: .bold))
                        .deejTracking(2)
                }
                .foregroundStyle(Color.deejOrangeHigh)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.deejButtonDark)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.deejOrangePrimary, lineWidth: 1)
                        }
                        .shadow(color: Color.deejOrangePrimary.opacity(0.2), radius: 12)
                }
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color.deejBgPanelEdge)
                .frame(height: 1)
                .padding(.top, 22)

            VStack(spacing: 4) {
                Button { onComplete() } label: {
                    Text("SKIP_FOR_NOW · LIMITED_MODE")
                        .font(.deejMono(9, weight: .semibold))
                        .foregroundStyle(Color.deejTextFaint)
                        .deejTracking(1.5)
                }
                .buttonStyle(.plain)

                Text("(discovery + recommendations disabled)")
                    .font(.deejMono(8))
                    .foregroundStyle(Color.deejEngraving)
                    .deejTracking(1)
            }
            .padding(.top, 14)
        }
    }
}

private struct SuggestedEvent: Identifiable, Hashable {
    let id = UUID()
    let artist: String
    let venue: String
    let dateLine: String
    let isBestMatch: Bool
}

#Preview {
    OnboardingView(onComplete: {})
        .preferredColorScheme(.dark)
}
