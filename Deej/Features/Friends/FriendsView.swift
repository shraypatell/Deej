//
//  FriendsView.swift
//  Friend search + pending requests + accepted-friends list.
//

import SwiftUI

struct FriendsView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var results: [AppUser] = []
    @State private var isSearching: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            navHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    searchSection
                    pendingSection
                    friendsSection
                    Spacer(minLength: 60)
                }
            }
        }
        .background(Color.deejBgCanvas.ignoresSafeArea())
        .task { await services.refreshFriends() }
    }

    // MARK: nav
    private var navHeader: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.deejCreamDim)
                    .frame(width: 36, height: 36)
                    .background {
                        Circle().fill(Color.deejButtonDark)
                            .overlay { Circle().strokeBorder(Color.deejBgPanelEdge, lineWidth: 1) }
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("CONNECT")
                    .font(.deejMono(8, weight: .semibold))
                    .foregroundStyle(.deejTextFaint)
                    .deejTracking(1.5)
                Text("FRIENDS")
                    .font(.deejMono(22, weight: .bold))
                    .foregroundStyle(.deejCream)
                    .deejTracking(0.5)
            }
            .padding(.leading, 8)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: search
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("SEARCH_USERS", subtitle: "by username · min 2 chars")

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.deejOrangeLow)
                TextField("@username", text: $query)
                    .font(.deejMono(13, weight: .semibold))
                    .foregroundStyle(.deejCream)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: query) { _, new in
                        Task { await runSearch(new) }
                    }
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.deejTextFaint)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.deejButtonDark)
                    .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(Color.deejBgPanelEdge, lineWidth: 1) }
            }

            if !results.isEmpty {
                VStack(spacing: 0) {
                    ForEach(results) { user in
                        searchRow(user: user)
                        Rectangle().fill(Color.deejBgPanelEdge).frame(height: 1)
                    }
                }
            } else if query.count >= 2 && !isSearching {
                Text("no users matched · \(query)")
                    .font(.deejMono(9))
                    .foregroundStyle(.deejTextFaint)
                    .padding(.top, 6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private func searchRow(user: AppUser) -> some View {
        HStack(spacing: 12) {
            avatarBadge(initials: String(user.username.prefix(2).uppercased()), close: false)
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(user.username)")
                    .font(.deejMono(12, weight: .bold))
                    .foregroundStyle(.deejCream)
                if let location = user.location {
                    Text(location)
                        .font(.deejMono(8))
                        .foregroundStyle(.deejOrangeLow)
                }
            }
            Spacer()
            connectActionButton(for: user)
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func connectActionButton(for user: AppUser) -> some View {
        switch relationship(with: user.id) {
        case .none:
            Button("+ ADD") {
                Task { await services.sendFriendRequest(to: user.id) }
            }
            .buttonStyle(.hardware(.primary))
            .font(.deejMono(10, weight: .bold))
            .deejTracking(2)
            .frame(width: 90, height: 32)

        case .pendingOutgoing:
            Text("REQUESTED")
                .font(.deejMono(9, weight: .bold))
                .foregroundStyle(.deejLEDAmber)
                .deejTracking(1.5)
                .frame(width: 90, height: 32)
                .background {
                    RoundedRectangle(cornerRadius: 6).fill(Color.deejButtonDark)
                        .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(Color.deejLEDAmber, lineWidth: 1) }
                }

        case .pendingIncoming:
            Text("RESPOND ↓")
                .font(.deejMono(9, weight: .bold))
                .foregroundStyle(.deejOrangeHigh)
                .deejTracking(1.5)
                .frame(width: 90, height: 32)

        case .friend:
            Text("● FRIEND")
                .font(.deejMono(9, weight: .bold))
                .foregroundStyle(.deejStatusGreen)
                .deejTracking(1.5)
                .frame(width: 90, height: 32)
        }
    }

    enum Relationship { case none, pendingOutgoing, pendingIncoming, friend }
    private func relationship(with userId: UUID) -> Relationship {
        if services.acceptedFriendships.contains(where: { $0.otherUserId(notMe: services.userId) == userId }) {
            return .friend
        }
        if services.pendingOutgoingFriendships.contains(where: { $0.recipientId == userId }) {
            return .pendingOutgoing
        }
        if services.pendingIncomingFriendships.contains(where: { $0.requesterId == userId }) {
            return .pendingIncoming
        }
        return .none
    }

    // MARK: pending
    @ViewBuilder
    private var pendingSection: some View {
        if !services.pendingIncomingFriendships.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("PENDING_REQUESTS",
                              subtitle: "\(services.pendingIncomingFriendships.count) WAITING_FOR_YOU")
                ForEach(services.pendingIncomingFriendships) { friendship in
                    pendingRow(friendship: friendship)
                    Rectangle().fill(Color.deejBgPanelEdge).frame(height: 1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
    }

    private func pendingRow(friendship: Friendship) -> some View {
        let other = services.friend(friendship)
        return HStack(spacing: 12) {
            avatarBadge(initials: String((other?.username ?? "??").prefix(2).uppercased()), close: false)
            Text("@\(other?.username ?? "unknown")")
                .font(.deejMono(12, weight: .bold))
                .foregroundStyle(.deejCream)
            Spacer()
            Button("ACCEPT") {
                Task { await services.acceptFriendRequest(friendship) }
            }
            .buttonStyle(.hardware(.primary))
            .font(.deejMono(9, weight: .bold))
            .deejTracking(1.5)
            .frame(width: 84, height: 30)

            Button("X") {
                Task { await services.declineFriendRequest(friendship) }
            }
            .buttonStyle(.hardware(.ghost))
            .font(.deejMono(10, weight: .bold))
            .frame(width: 36, height: 30)
        }
        .padding(.vertical, 8)
    }

    // MARK: friends list
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("YOUR_FRIENDS",
                          subtitle: "\(services.acceptedFriendships.count) MUTUAL")
            if services.acceptedFriendships.isEmpty {
                Text("no friends yet · search above to add some")
                    .font(.deejMono(9))
                    .foregroundStyle(.deejTextFaint)
                    .padding(.top, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(services.acceptedFriendships) { friendship in
                        friendRow(friendship: friendship)
                        Rectangle().fill(Color.deejBgPanelEdge).frame(height: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private func friendRow(friendship: Friendship) -> some View {
        let other = services.friend(friendship)
        return HStack(spacing: 12) {
            avatarBadge(initials: String((other?.username ?? "??").prefix(2).uppercased()), close: true)
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(other?.username ?? "unknown")")
                    .font(.deejMono(12, weight: .bold))
                    .foregroundStyle(.deejCream)
                Text("connected · \(shortDate(friendship.updatedAt))")
                    .font(.deejMono(8))
                    .foregroundStyle(.deejOrangeLow)
            }
            Spacer()
            Text("● ACTIVE")
                .font(.deejMono(9, weight: .bold))
                .foregroundStyle(.deejStatusGreen)
                .deejTracking(1.5)
        }
        .padding(.vertical, 10)
    }

    // MARK: helpers
    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        HStack {
            Text(title)
                .font(.deejMono(10, weight: .semibold))
                .foregroundStyle(.deejCreamDim)
                .deejTracking(1.5)
            Spacer()
            Text(subtitle)
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(.deejOrangeLow)
                .deejTracking(1.2)
        }
    }

    private func avatarBadge(initials: String, close: Bool) -> some View {
        ZStack {
            Circle().fill(Color.deejButtonDark)
                .overlay {
                    Circle().strokeBorder(close ? Color.deejOrangePrimary : Color.deejOrangeLow,
                                          lineWidth: close ? 1.5 : 1)
                }
            Text(initials)
                .font(.deejMono(11, weight: .bold))
                .foregroundStyle(close ? Color.deejOrangeHigh : Color.deejOrangeMid)
        }
        .frame(width: 36, height: 36)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM dd ''yy"
        return f.string(from: date).uppercased()
    }

    private func runSearch(_ raw: String) async {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            results = []
            return
        }
        isSearching = true
        results = await services.searchUsers(matching: trimmed)
        isSearching = false
    }
}

#Preview {
    FriendsView()
        .environment(AppServices())
        .preferredColorScheme(.dark)
}
