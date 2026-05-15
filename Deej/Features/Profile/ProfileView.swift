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
    @Environment(AppServices.self) private var services

    @State private var showSettings: Bool = false

    var body: some View {
        NavigationStack {
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
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: FriendsDestination.self) { _ in
                FriendsView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color.deejBgCanvas)
            }
        }
    }

    private struct FriendsDestination: Hashable {}

    // MARK: derived user fields
    private var resolvedUsername: String {
        if let u = services.currentUser?.username, !u.isEmpty { return "@\(u)" }
        return "@you"
    }
    private var resolvedBio: String {
        services.currentUser?.bio ?? "tap the gear to set your bio"
    }
    private var resolvedLocation: String {
        if let loc = services.currentUser?.location, !loc.isEmpty {
            return "● \(loc)"
        }
        return "● tap settings to set your city"
    }
    private var resolvedInitials: String {
        let raw = services.currentUser?.displayName ?? services.currentUser?.username ?? "you"
        let words = raw.split(separator: " ")
        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }
        return String(raw.prefix(2)).uppercased()
    }

    // MARK: nav
    private var navHeader: some View {
        HStack {
            Text("PROFILE")
                .font(.deejMono(12, weight: .semibold))
                .foregroundStyle(.deejTextFaint)
                .deejTracking(2)
            Spacer()
            ShareLink(item: shareText, subject: Text("My Deej profile")) {
                roundIconLabel("square.and.arrow.up")
            }
            roundIcon("gearshape") { showSettings = true }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var shareText: String {
        let name = services.currentUser?.username ?? "me"
        let logs = services.orderedLogs.count
        let avg  = avgScoreString
        return "@\(name) on Deej · \(logs) events logged · avg \(avg)/10"
    }

    private func roundIcon(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { roundIconLabel(name) }
            .buttonStyle(.plain)
    }

    private func roundIconLabel(_ name: String) -> some View {
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
                Text(resolvedInitials)
                    .font(.deejMono(26, weight: .bold))
                    .foregroundStyle(.deejOrangeHigh)
                    .deejTracking(1)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 2) {
                Text(resolvedUsername)
                    .font(.deejMono(22, weight: .bold))
                    .foregroundStyle(.deejCream)
                    .deejTracking(0.5)
                Text(resolvedBio)
                    .font(.deejMono(10, weight: .medium))
                    .foregroundStyle(.deejOrangeLow)
                Text(resolvedLocation)
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
            OLEDStatChip(label: "FRIENDS",   value: "\(services.acceptedFriendships.count)",
                         valueColor: .deejCream)
            OLEDStatChip(label: "LOGGED",    value: "\(services.orderedLogs.count)",
                         valueColor: .deejOrangeHigh)
            OLEDStatChip(label: "AVG_SCORE", value: avgScoreString,
                         valueColor: .deejOrangeBright)
        }
        .frame(height: 60)
        .padding(.horizontal, 16)
    }

    private var avgScoreString: String {
        guard !services.orderedLogs.isEmpty else { return "—" }
        let sum = services.orderedLogs.reduce(0) { $0 + $1.aggregateScore }
        let avg = sum / Double(services.orderedLogs.count)
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
            Text("FROM \(services.orderedLogs.count)_EVENTS")
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(.deejOrangeLow)
                .deejTracking(1.2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private var tasteSubtitle: some View {
        Text(services.orderedLogs.isEmpty
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
        let isTopDim = dim == sortedDimensions.first?.0 && !services.orderedLogs.isEmpty
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
        services.orderedLogs.reduce(TasteVector.empty) { $0.adding($1) }
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
        NavigationLink(value: FriendsDestination()) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("YOUR_FRIENDS")
                        .font(.deejMono(10, weight: .semibold))
                        .foregroundStyle(.deejCreamDim)
                        .deejTracking(1.5)
                    Spacer()
                    Text(viewAllLabel)
                        .font(.deejMono(9, weight: .semibold))
                        .foregroundStyle(.deejOrangeHigh)
                        .deejTracking(1.2)
                }

                friendAvatarsRow

                if pendingIncomingCount > 0 {
                    Text("● \(pendingIncomingCount) PENDING_REQUEST\(pendingIncomingCount == 1 ? "" : "S")")
                        .font(.deejMono(9, weight: .bold))
                        .foregroundStyle(.deejLEDAmber)
                        .deejTracking(1.5)
                        .padding(.top, 4)
                } else if services.acceptedFriendships.isEmpty {
                    Text("tap to find people to log nights with")
                        .font(.deejMono(9))
                        .foregroundStyle(.deejEngraving)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var pendingIncomingCount: Int {
        services.pendingIncomingFriendships.count
    }

    private var viewAllLabel: String {
        let count = services.acceptedFriendships.count
        return "VIEW_ALL · \(count) ▸"
    }

    private var friendAvatarsRow: some View {
        HStack(spacing: 12) {
            let accepted = services.acceptedFriendships
            let me = services.userId
            ForEach(Array(accepted.prefix(5).enumerated()), id: \.offset) { idx, friendship in
                let user = services.friendUsers[friendship.otherUserId(notMe: me)]
                let initials = String((user?.username ?? "??").prefix(2).uppercased())
                ZStack {
                    Circle().fill(Color.deejButtonDark)
                        .overlay {
                            Circle().strokeBorder(idx == 0 ? Color.deejOrangePrimary : Color.deejOrangeLow,
                                                  lineWidth: idx == 0 ? 1.5 : 1)
                        }
                    Text(initials)
                        .font(.deejMono(11, weight: .bold))
                        .foregroundStyle(idx == 0 ? Color.deejOrangeHigh : Color.deejOrangeMid)
                }
                .frame(width: 44, height: 44)
            }
            // pad with empty slots to keep visual rhythm
            ForEach(accepted.count..<5, id: \.self) { _ in
                Circle()
                    .fill(Color.deejButtonDark.opacity(0.4))
                    .frame(width: 44, height: 44)
                    .overlay { Circle().strokeBorder(Color.deejBgPanelEdge, lineWidth: 1) }
            }
            Spacer()
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppServices())
}
