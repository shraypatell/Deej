//
//  AttendedView.swift
//  Real archive list reading from LocalEventStore (Phase 4).
//  Phase 4.8 swaps this to Supabase-backed once SDK is wired.
//

import SwiftUI

struct AttendedView: View {
    @Environment(AppServices.self) private var services

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                navHeader
                ScrollView {
                    VStack(spacing: 0) {
                        statsRow
                        chipsRow
                        bestCaptureCardIfAny
                        listHeader
                        if services.orderedLogs.isEmpty {
                            emptyState
                        } else {
                            cassetteStack
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .background(Color.deejBgCanvas.ignoresSafeArea())
            .navigationDestination(for: EventLog.self) { log in
                EventDetailView(log: log)
                    .toolbar(.hidden, for: .navigationBar)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: header
    private var navHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ARCHIVE_v1")
                    .font(.deejMono(8, weight: .semibold))
                    .foregroundStyle(Color.deejTextFaint)
                    .deejTracking(1.5)
                Text("ATTENDED")
                    .font(.deejMono(24, weight: .bold))
                    .foregroundStyle(Color.deejCream)
                    .deejTracking(0.5)
            }
            Spacer()
            HStack(spacing: 8) {
                roundIcon("magnifyingglass")
                roundIcon("slider.horizontal.3")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private func roundIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 14))
            .foregroundStyle(Color.deejCreamDim)
            .frame(width: 36, height: 36)
            .background {
                Circle()
                    .fill(Color.deejButtonDark)
                    .overlay { Circle().strokeBorder(Color.deejBgPanelEdge, lineWidth: 1) }
            }
    }

    // MARK: stats
    private var statsRow: some View {
        HStack(spacing: 8) {
            OLEDStatChip(label: "LOGGED",    value: "\(services.orderedLogs.count)", valueColor: .deejCream)
            OLEDStatChip(label: "TOP_RATED", value: "\(topRatedCount)",            valueColor: .deejOrangeHigh)
            OLEDStatChip(label: "AVG_SCORE", value: avgScoreString,                valueColor: .deejOrangeBright)
        }
        .frame(height: 76)
        .padding(.top, 4)
    }

    private var topRatedCount: Int {
        services.orderedLogs.filter { $0.aggregateScore >= 8.5 }.count
    }

    private var avgScoreString: String {
        guard !services.orderedLogs.isEmpty else { return "—" }
        let sum = services.orderedLogs.reduce(0.0) { $0 + $1.aggregateScore }
        let avg = sum / Double(services.orderedLogs.count)
        return avg.formatted(.number.precision(.fractionLength(2)))
    }

    // MARK: chips
    private var chipsRow: some View {
        HStack(spacing: 8) {
            chip("ALL · \(services.orderedLogs.count)", active: true)
            chip("TOP · \(topRatedCount)", active: false)
            chip("RECENT", active: false)
            chip("ARCHIVED", active: false)
            Spacer()
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    private func chip(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(.deejMono(10, weight: active ? .bold : .semibold))
            .foregroundStyle(active ? Color.deejBgScreen : Color.deejCreamDim)
            .deejTracking(1.2)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(active ? Color.deejOrangePrimary : Color.deejButtonDark)
                    .overlay {
                        Capsule().strokeBorder(active ? Color.deejOrangeBright : Color.deejBgPanelEdge,
                                               lineWidth: 1)
                    }
            }
    }

    // MARK: best capture
    @ViewBuilder
    private var bestCaptureCardIfAny: some View {
        if let best = services.bestCapture, let event = services.event(byId: best.eventId) {
            HighlightStripeCard(tint: .deejStatusGreen) {
                HStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("● BEST_CAPTURE")
                                .font(.deejMono(8, weight: .bold))
                                .foregroundStyle(.deejStatusGreen)
                                .deejTracking(1.5)
                            Text("· \(shortDate(event.eventDate))")
                                .font(.deejMono(8, weight: .semibold))
                                .foregroundStyle(.deejCreamDim)
                                .deejTracking(1.2)
                        }
                        Text(event.artistName)
                            .font(.deejMono(18, weight: .bold))
                            .foregroundStyle(.deejCream)
                            .deejTracking(0.5)
                        Text("\(event.venueName) · \(dateString(event.eventDate))")
                            .font(.deejMono(9))
                            .foregroundStyle(.deejOrangeLow)
                    }
                    .padding(.vertical, 14)

                    Spacer(minLength: 8)

                    VStack(spacing: 2) {
                        Text("SCORE")
                            .font(.deejMono(8, weight: .semibold))
                            .foregroundStyle(.deejCreamDim)
                            .deejTracking(1.5)
                        Text(best.aggregateScore.formatted(.number.precision(.fractionLength(2))))
                            .font(.deejMono(28, weight: .bold))
                            .foregroundStyle(.deejOrangeHigh)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 12)
        }
    }

    // MARK: list
    private var listHeader: some View {
        HStack {
            Text("RECENT_LOGS")
                .deejTracking(1.5)
            Spacer()
            Text("↓ NEWEST_FIRST")
                .deejTracking(1.2)
                .foregroundStyle(Color.deejOrangeLow)
        }
        .font(.deejMono(10, weight: .semibold))
        .foregroundStyle(Color.deejCreamDim)
        .padding(.top, 22)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("NO_EVENTS_YET")
                .font(.deejMono(14, weight: .bold))
                .foregroundStyle(.deejCream)
                .deejTracking(1.5)
            Text("tap + to log your first event")
                .font(.deejMono(10))
                .foregroundStyle(.deejOrangeLow)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // Renders the user's logs as a vertical pile of cassette tapes —
    // dark VHS-style body with a cream sticker label across the middle.
    // 0 spacing so each cassette's dark bottom seam butts up against the
    // next tape's top edge, visually reading as a stacked pile.
    private var cassetteStack: some View {
        VStack(spacing: 0) {
            ForEach(services.orderedLogs) { log in
                if let event = services.event(byId: log.eventId) {
                    NavigationLink(value: log) {
                        StackedCassette(event: event, log: log)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.deejBgPanelEdge)
            .frame(height: 1)
    }

    // MARK: helpers
    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM.dd.yy"
        return f.string(from: date)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM ''yy"
        return f.string(from: date).uppercased()
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 9...:  .deejOrangeHigh
        case 7..<9: .deejOrangeBright
        case 5..<7: .deejOrangeMid
        default:    .deejOrangeLow
        }
    }
}

#Preview {
    AttendedView()
        .environment(AppServices())
}
