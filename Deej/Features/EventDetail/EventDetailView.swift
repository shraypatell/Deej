//
//  EventDetailView.swift
//  Read-only view of a logged event: cassette hero + 7-dimension breakdown
//  + action buttons. Tapped from the Attended list.
//

import SwiftUI

struct EventDetailView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss

    let log: EventLog

    private var event: Event? { services.event(byId: log.eventId) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topRow
                if let event {
                    CassetteCard(event: event, log: log, style: .full)
                        .padding(.top, 8)
                }
                breakdownHeader
                breakdownBars
                actionsRow
                bottomEngraving
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.deejBgPanel.ignoresSafeArea())
    }

    private var topRow: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.deejCreamDim)
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(Color.deejButtonDark)
                            .overlay { Circle().strokeBorder(Color.deejBgPanelEdge, lineWidth: 1) }
                    }
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 4) {
                Text("DEEJ.SYS")
                Spacer().frame(width: 12)
                Text("MOD-05 / EVENT_DETAIL")
                StatusLED(state: .ok, size: 5).padding(.leading, 6)
            }
            .font(.deejMono(8, weight: .medium))
            .foregroundStyle(.deejEngraving)
            .deejTracking(1.5)
        }
    }

    private var breakdownHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Text("RATING_BREAKDOWN")
                    .deejTracking(1.5)
                    .foregroundStyle(.deejOrangeLow)
                Spacer()
                Text("AGG_SCORE")
                    .deejTracking(1.5)
                    .foregroundStyle(.deejCreamDim)
                Text(log.aggregateScore.formatted(.number.precision(.fractionLength(2))))
                    .font(.deejMono(11, weight: .bold))
                    .foregroundStyle(.deejOrangeHigh)
            }
            .font(.deejMono(9, weight: .semibold))
            Rectangle()
                .fill(Color.deejOrangeTrack)
                .frame(height: 1)
        }
        .padding(.top, 22)
    }

    private var breakdownBars: some View {
        VStack(spacing: 8) {
            ForEach(Dimension.rankingOrder, id: \.self) { d in
                breakdownRow(d, value: log.dimensionRatings[d] ?? 0)
            }
        }
        .padding(.top, 14)
    }

    private func breakdownRow(_ d: Dimension, value: Int) -> some View {
        HStack(spacing: 12) {
            Text(d.displayLabel)
                .font(.deejMono(8, weight: .medium))
                .foregroundStyle(.deejOrangeLow)
                .deejTracking(0.4)
                .frame(width: 144, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            GeometryReader { geo in
                let progress = CGFloat(value - 1) / 9
                let active = geo.size.width * progress
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.deejOrangeTrack).frame(height: 2)
                    Capsule()
                        .fill(barColor(for: value))
                        .frame(width: active, height: 2)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 10)
            Text(value.formatted(.number.precision(.fractionLength(1))))
                .font(.deejMono(11, weight: .bold))
                .foregroundStyle(.deejOrangeMid)
                .frame(width: 32, alignment: .trailing)
        }
        .frame(height: 22)
    }

    private func barColor(for value: Int) -> Color {
        switch value {
        case 9...10: .deejOrangeHigh
        case 7...8:  .deejOrangeBright
        case 5...6:  .deejOrangeMid
        default:     .deejOrangeLow
        }
    }

    private var actionsRow: some View {
        HStack(spacing: 10) {
            Button { } label: {
                VStack(spacing: 1) {
                    Text("EDIT").font(.deejMono(13, weight: .bold)).deejTracking(2)
                    Text("RATING").font(.deejMono(7, weight: .semibold)).deejTracking(1.5).opacity(0.7)
                }
            }
            .buttonStyle(.hardware(.primary))
            .frame(height: 56)

            Button { } label: {
                VStack(spacing: 1) {
                    Text("SHARE").font(.deejMono(12, weight: .bold)).deejTracking(2)
                    Text("TO_FRIENDS").font(.deejMono(7, weight: .semibold)).deejTracking(1.5).opacity(0.7)
                }
            }
            .buttonStyle(.hardware(.secondary))
            .frame(height: 56)

            Button { } label: {
                VStack(spacing: 1) {
                    Text("ARCHIVE").font(.deejMono(11, weight: .bold)).deejTracking(2)
                    Text("MOVE_OFF").font(.deejMono(7, weight: .semibold)).deejTracking(1.5).opacity(0.7)
                }
            }
            .buttonStyle(.hardware(.ghost))
            .frame(height: 56)
        }
        .padding(.top, 28)
    }

    private var bottomEngraving: some View {
        Text("ARCHIVE.LOG_v1 · IMMUTABLE_RECORD")
            .font(.deejMono(9, weight: .medium))
            .foregroundStyle(.deejEngraving)
            .deejTracking(2)
            .frame(maxWidth: .infinity)
            .padding(.top, 36)
    }
}

#Preview {
    let services = AppServices()
    let log = EventLog(
        id: UUID(), userId: UUID(), eventId: UUID(),
        ratingArtistPerformance: 8, ratingCrowdEnergy: 9, ratingVenue: 7,
        ratingLightingVisuals: 9, ratingMusicSelection: 6, ratingAtmosphereVibe: 9, ratingValue: 7,
        aggregateScore: 7.86, notes: "biggest crowd at K_C", photoURLs: [],
        status: .active, createdAt: .now, updatedAt: .now)
    return EventDetailView(log: log)
        .environment(services)
        .preferredColorScheme(.dark)
}
