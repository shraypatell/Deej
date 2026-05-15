//
//  ProfileView.swift
//  Own-profile view. Reads logs from LocalEventStore, computes the user's
//  taste vector live, and renders the iOS-native-with-hardware-accents layout
//  from the Pencil design.
//
//  See PLAN.md §1.7b for own-vs-others verbiage rules — currently the screen
//  hard-codes the "own" copy ("YOUR_FRIENDS" / "what you reward most").
//

import SwiftUI

struct ProfileView: View {
    @Environment(LocalEventStore.self) private var store

    // Hard-coded user identity for v0; real Sign in with Apple lands in Phase 5.
    private let username  = "@you"
    private let bio       = "warehouse + club nights, mostly techno"
    private let location  = "● BKLYN, NY · LOGGING SINCE '22"
    private let initials  = "SP"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                navHeader
                hero
                statsRow
                tasteHeader
                tasteSubtitle
                tasteBars
                friendsSection
                Spacer(minLength: 100)
            }
            .padding(.bottom, 60)
        }
        .background(Color.deejBgCanvas.ignoresSafeArea())
    }

    // MARK: nav
    private var navHeader: some View {
        HStack {
            Text("PROFILE")
                .font(.deejMono(12, weight: .semibold))
                .foregroundStyle(.deejTextFaint)
                .deejTracking(2)
            Spacer()
            roundIcon("square.and.arrow.up")
            roundIcon("gearshape")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private func roundIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 13))
            .foregroundStyle(.deejCreamDim)
            .frame(width: 36, height: 36)
            .background {
                Circle()
                    .fill(Color.deejButtonDark)
                    .overlay { Circle().strokeBorder(Color.deejBgPanelEdge, lineWidth: 1) }
            }
    }

    // MARK: hero
    private var hero: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.deejButtonDark)
                    .overlay { Circle().strokeBorder(Color.deejOrangePrimary, lineWidth: 2) }
                    .shadow(color: Color.deejOrangePrimary.opacity(0.4), radius: 16)
                Text(initials)
                    .font(.deejMono(26, weight: .bold))
                    .foregroundStyle(.deejOrangeHigh)
                    .deejTracking(1)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 2) {
                Text(username)
                    .font(.deejMono(22, weight: .bold))
                    .foregroundStyle(.deejCream)
                    .deejTracking(0.5)
                Text(bio)
                    .font(.deejMono(10, weight: .medium))
                    .foregroundStyle(.deejOrangeLow)
                Text(location)
                    .font(.deejMono(9, weight: .semibold))
                    .foregroundStyle(.deejCreamDim)
                    .deejTracking(1.2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: stats
    private var statsRow: some View {
        HStack(spacing: 8) {
            OLEDStatChip(label: "FRIENDS",   value: "0",
                         valueColor: .deejCream)
            OLEDStatChip(label: "LOGGED",    value: "\(store.orderedLogs.count)",
                         valueColor: .deejOrangeHigh)
            OLEDStatChip(label: "AVG_SCORE", value: avgScoreString,
                         valueColor: .deejOrangeBright)
        }
        .frame(height: 60)
        .padding(.horizontal, 16)
    }

    private var avgScoreString: String {
        guard !store.orderedLogs.isEmpty else { return "—" }
        let sum = store.orderedLogs.reduce(0) { $0 + $1.aggregateScore }
        let avg = sum / Double(store.orderedLogs.count)
        return avg.formatted(.number.precision(.fractionLength(2)))
    }

    // MARK: taste profile
    private var tasteHeader: some View {
        HStack {
            Text("TASTE_PROFILE")
                .font(.deejMono(10, weight: .semibold))
                .foregroundStyle(.deejCreamDim)
                .deejTracking(1.5)
            Spacer()
            Text("FROM \(store.orderedLogs.count)_EVENTS")
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(.deejOrangeLow)
                .deejTracking(1.2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private var tasteSubtitle: some View {
        Text(store.orderedLogs.isEmpty
             ? "log events to build your taste profile"
             : "what you reward most across all logged events")
            .font(.deejMono(9, weight: .medium))
            .foregroundStyle(.deejOrangeLow)
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 12)
    }

    private var tasteBars: some View {
        VStack(spacing: 6) {
            ForEach(sortedDimensions, id: \.0) { dim, score in
                tasteBarRow(dim: dim, score: score)
            }
        }
        .padding(.horizontal, 20)
    }

    private func tasteBarRow(dim: Dimension, score: Double) -> some View {
        let isTopDim = dim == sortedDimensions.first?.0 && !store.orderedLogs.isEmpty
        return HStack(spacing: 12) {
            Text(dim.displayLabel)
                .font(.deejMono(8, weight: isTopDim ? .bold : .medium))
                .foregroundStyle(isTopDim ? Color.deejOrangeHigh : Color.deejCreamDim)
                .deejTracking(0.4)
                .frame(width: 124, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            GeometryReader { geo in
                let progress = max(0, min(1, score / 10))
                let active = geo.size.width * progress
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.deejOrangeTrack).frame(height: 4)
                    Capsule()
                        .fill(barColor(score: score))
                        .frame(width: active, height: 4)
                        .shadow(color: isTopDim ? Color.deejOrangePrimary : .clear,
                                radius: 4)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 16)

            Text(score > 0 ? score.formatted(.number.precision(.fractionLength(1))) : "—")
                .font(.deejMono(11, weight: .bold))
                .foregroundStyle(isTopDim ? Color.deejOrangeHigh : Color.deejOrangeMid)
                .frame(width: 28, alignment: .trailing)
        }
        .frame(height: 22)
    }

    private var sortedDimensions: [(Dimension, Double)] {
        let vector = computedTasteVector
        return Dimension.allCases
            .map { ($0, vector.averages[$0] ?? 0) }
            .sorted { $0.1 > $1.1 }
    }

    private var computedTasteVector: TasteVector {
        store.orderedLogs.reduce(TasteVector.empty) { $0.adding($1) }
    }

    private func barColor(score: Double) -> Color {
        switch score {
        case 8.5...: .deejOrangeHigh
        case 7..<8.5: .deejOrangeBright
        case 5.5..<7: .deejOrangeMid
        case 0.001..<5.5: .deejOrangeLow
        default: .deejOrangeDeep
        }
    }

    // MARK: friends
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("YOUR_FRIENDS")
                    .font(.deejMono(10, weight: .semibold))
                    .foregroundStyle(.deejCreamDim)
                    .deejTracking(1.5)
                Spacer()
                Text("VIEW_ALL · 0 ▸")
                    .font(.deejMono(9, weight: .semibold))
                    .foregroundStyle(.deejOrangeLow)
                    .deejTracking(1.2)
            }

            HStack(spacing: 12) {
                ForEach(0..<5) { _ in
                    Circle()
                        .fill(Color.deejButtonDark)
                        .frame(width: 44, height: 44)
                        .overlay { Circle().strokeBorder(Color.deejBgPanelEdge, lineWidth: 1) }
                }
                Spacer()
            }

            Text("add friends in phase 5 to see mutual events")
                .font(.deejMono(9))
                .foregroundStyle(.deejEngraving)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }
}

#Preview {
    ProfileView()
        .environment(LocalEventStore())
}
