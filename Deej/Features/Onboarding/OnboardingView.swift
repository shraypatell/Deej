//
//  OnboardingView.swift
//  First-run flow: boot status terminal → suggested events → tap to rate first.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppServices.self) private var services

    let onComplete: () -> Void

    @State private var rankingEvent: Event?

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
        .sheet(item: $rankingEvent) { event in
            EventRankingView(event: event) { _ in
                onComplete()
            }
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.deejBgCanvas)
            .interactiveDismissDisabled(false)
        }
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

    // MARK: boot status
    private var bootStatus: some View {
        VStack(alignment: .leading, spacing: 4) {
            bootRow(state: .ok,       label: "AUDIO_ENGINE.READY",  tail: "[OK]",        tailColor: .deejStatusGreen)
            bootRow(state: .ok,       label: "LOCATION.PERMISSION", tail: "[OK]",        tailColor: .deejStatusGreen)
            bootRow(state: .pending,  label: "USER_PROFILE",        tail: "[PENDING]",   tailColor: .deejLEDAmber)
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

    // MARK: suggestions
    private var sectionHeader: some View {
        HStack {
            Text("SELECT_FROM_NEARBY_RECENT")
                .deejTracking(1.5)
            Spacer()
            Text("\(services.suggestedEvents.count) SUGGESTIONS")
                .deejTracking(1.2)
                .foregroundStyle(Color.deejOrangeLow)
        }
        .font(.deejMono(9, weight: .semibold))
        .foregroundStyle(Color.deejCreamDim)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private var suggestionsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(services.suggestedEvents.prefix(4).enumerated()), id: \.element.id) { idx, event in
                Button {
                    rankingEvent = event
                } label: {
                    row(for: event, isBestMatch: idx == 0)
                }
                .buttonStyle(.plain)
                Rectangle()
                    .fill(Color.deejOrangeTrack)
                    .frame(height: 1)
                    .padding(.leading, 16)
            }
        }
    }

    private func row(for event: Event, isBestMatch: Bool) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isBestMatch ? Color.deejOrangeBright : .clear)
                .frame(width: 3)
                .shadow(color: isBestMatch ? Color.deejOrangePrimary : .clear, radius: 6)

            VStack(alignment: .leading, spacing: 4) {
                if isBestMatch {
                    HStack {
                        Spacer()
                        Text("● BEST_MATCH")
                            .font(.deejMono(8, weight: .bold))
                            .foregroundStyle(Color.deejStatusGreen)
                            .deejTracking(1.2)
                    }
                }
                Text(event.artistName)
                    .font(.deejMono(14, weight: isBestMatch ? .bold : .semibold))
                    .foregroundStyle(isBestMatch ? Color.deejCream : Color.deejOrangeMid)
                Text("\(event.venueName) · \(eventDateString(event.eventDate))")
                    .font(.deejMono(8))
                    .foregroundStyle(Color.deejOrangeLow)
                    .deejTracking(0.8)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)

            Spacer(minLength: 0)

            Text("▸")
                .font(.deejMono(16, weight: .bold))
                .foregroundStyle(isBestMatch ? Color.deejStatusGreen : Color.deejOrangeLow)
                .padding(.trailing, 12)
        }
        .contentShape(Rectangle())
    }

    private func eventDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd · EEE HH:mm"
        return f.string(from: date).uppercased()
    }

    // MARK: bottom CTAs
    private var ctaBlock: some View {
        VStack(spacing: 14) {
            Text("didn't see your event in the list?")
                .font(.deejMono(10))
                .foregroundStyle(Color.deejOrangeLow)
                .padding(.top, 20)

            Button {
                if let any = services.suggestedEvents.last {
                    rankingEvent = any
                }
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

// Event already conforms to Identifiable, so .sheet(item:) works directly.

#Preview {
    OnboardingView(onComplete: {})
        .environment(AppServices())
        .preferredColorScheme(.dark)
}
