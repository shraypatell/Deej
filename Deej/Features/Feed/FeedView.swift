//
//  FeedView.swift
//  Social activity stream. Reads `public.activity_feed` via AppServices —
//  RLS scopes the rows to self + accepted friends. Falls back to a helpful
//  empty state when the feed is empty.
//

import SwiftUI

struct FeedView: View {
    @Environment(AppServices.self) private var services
    @State private var filter: FeedFilter = .all

    enum FeedFilter: String, CaseIterable, Identifiable {
        case all          = "ALL"
        case rated        = "RATED"
        case milestone    = "MILESTONES"
        var id: String { rawValue }
    }

    private var filteredActivities: [FeedActivity] {
        switch filter {
        case .all:       return services.feedActivities
        case .rated:     return services.feedActivities.filter { $0.type == .ratedEvent }
        case .milestone: return services.feedActivities.filter { $0.type == .milestone }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            navHeader
            ScrollView {
                LazyVStack(spacing: 12) {
                    if filteredActivities.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredActivities) { activity in
                            feedCard(for: activity)
                        }
                    }
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .refreshable { await services.refreshActivityFeed() }
        }
        .background(Color.deejBgCanvas.ignoresSafeArea())
    }

    // MARK: nav
    private var navHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ACTIVITY · \(services.acceptedFriendships.count)_FRIENDS")
                    .font(.deejMono(8, weight: .semibold))
                    .foregroundStyle(.deejTextFaint)
                    .deejTracking(1.5)
                Text("FEED")
                    .font(.deejMono(24, weight: .bold))
                    .foregroundStyle(.deejCream)
                    .deejTracking(0.5)
            }
            Spacer()
            livePill
            filterMenu
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var livePill: some View {
        HStack(spacing: 6) {
            Circle().fill(.deejStatusGreen).frame(width: 5, height: 5)
            Text("LIVE")
                .font(.deejMono(8, weight: .bold))
                .foregroundStyle(.deejStatusGreen)
                .deejTracking(1.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule().fill(Color.deejButtonDark)
                .overlay { Capsule().strokeBorder(Color.deejBgPanelEdge, lineWidth: 1) }
        }
    }

    private func roundIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 13))
            .foregroundStyle(.deejCreamDim)
            .frame(width: 36, height: 36)
            .background {
                Circle().fill(Color.deejButtonDark)
                    .overlay { Circle().strokeBorder(Color.deejBgPanelEdge, lineWidth: 1) }
            }
    }

    private var filterMenu: some View {
        Menu {
            ForEach(FeedFilter.allCases) { option in
                Button {
                    filter = option
                } label: {
                    Label(option.rawValue.capitalized,
                          systemImage: filter == option ? "checkmark" : "")
                }
            }
        } label: {
            ZStack {
                Circle().fill(Color.deejButtonDark)
                    .overlay { Circle().strokeBorder(filter == .all
                                                     ? Color.deejBgPanelEdge
                                                     : Color.deejOrangePrimary,
                                                     lineWidth: 1) }
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 13))
                    .foregroundStyle(filter == .all ? .deejCreamDim : .deejOrangeHigh)
            }
            .frame(width: 36, height: 36)
        }
    }

    // MARK: empty state
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.deejOrangeLow)
            Text("NO_ACTIVITY_YET")
                .font(.deejMono(12, weight: .bold))
                .foregroundStyle(.deejCream)
                .deejTracking(2)
            Text(services.acceptedFriendships.isEmpty
                 ? "add friends to see what they're rating"
                 : "your friends haven't logged anything yet")
                .font(.deejMono(9))
                .foregroundStyle(.deejOrangeLow)
            Text("your own ratings will also show up here")
                .font(.deejMono(8))
                .foregroundStyle(.deejEngraving)
                .deejTracking(1)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: card switcher
    @ViewBuilder
    private func feedCard(for activity: FeedActivity) -> some View {
        switch activity.type {
        case .ratedEvent:
            if let event = services.activityEvent(for: activity) {
                ratedCard(activity: activity, event: event)
            } else {
                missingEventRow(activity: activity)
            }
        case .milestone:
            milestoneCard(activity: activity)
        case .goingToEvent, .addedToWant, .friendJoined:
            simpleRow(activity: activity)
        }
    }

    // MARK: rated_event
    private func ratedCard(activity: FeedActivity, event: Event) -> some View {
        // Build a synthetic EventLog from the metadata so CassetteCard.mini can render.
        let log = EventLog(
            id: activity.id,
            userId: activity.userId,
            eventId: event.id,
            ratingArtistPerformance: 0, ratingCrowdEnergy: 0, ratingVenue: 0,
            ratingLightingVisuals: 0, ratingMusicSelection: 0, ratingAtmosphereVibe: 0, ratingValue: 0,
            aggregateScore: activity.metadata.score ?? 0,
            notes: nil, photoURLs: [],
            status: .active,
            createdAt: activity.createdAt, updatedAt: activity.createdAt)

        return VStack(alignment: .leading, spacing: 10) {
            header(activity: activity, verb: "rated", subject: event.artistName)
            CassetteCard(event: event, log: log, style: .mini)
            footerActions(for: activity, event: event)
        }
        .padding(14)
        .background(cardBackground)
    }

    private func footerActions(for activity: FeedActivity, event: Event) -> some View {
        let count = services.reactions(for: activity.id).count
        let liked = services.iHaveReacted(to: activity.id)
        return HStack(spacing: 14) {
            Button {
                Task { await services.toggleReaction(on: activity.id) }
            } label: {
                Text("\(liked ? "♥" : "♡") \(count > 0 ? "\(count) " : "")\(liked ? "LIKED" : "LIKE")")
                    .font(.deejMono(9, weight: liked ? .bold : .semibold))
                    .foregroundStyle(liked ? Color.deejStatusRed : Color.deejCreamDim)
                    .deejTracking(1.2)
            }
            .buttonStyle(.plain)
            ShareLink(item: "\(event.artistName) · \(event.venueName) · on Deej") {
                Text("↗ SHARE")
                    .font(.deejMono(9, weight: .semibold))
                    .foregroundStyle(.deejOrangeLow)
                    .deejTracking(1.2)
            }
            Spacer()
        }
    }

    private func milestoneCard(activity: FeedActivity) -> some View {
        HStack(spacing: 12) {
            avatar(for: activity)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("@\(actorHandle(activity))")
                        .font(.deejMono(12, weight: .bold))
                        .foregroundStyle(.deejCream)
                    Text("unlocked")
                        .font(.deejMono(11, weight: .medium))
                        .foregroundStyle(.deejOrangeLow)
                    Text(activity.metadata.badge ?? "BADGE")
                        .font(.deejMono(12, weight: .bold))
                        .foregroundStyle(.deejStatusGreen)
                        .deejTracking(0.5)
                }
                if let blurb = activity.metadata.blurb {
                    Text(blurb)
                        .font(.deejMono(9))
                        .foregroundStyle(.deejOrangeLow)
                }
            }
            Spacer()
            timestampText(activity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(cardBackground)
    }

    private func simpleRow(activity: FeedActivity) -> some View {
        HStack(spacing: 12) {
            avatar(for: activity)
            Text("@\(actorHandle(activity)) · \(activity.type.rawValue)")
                .font(.deejMono(11, weight: .semibold))
                .foregroundStyle(.deejCream)
            Spacer()
            timestampText(activity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(cardBackground)
    }

    private func missingEventRow(activity: FeedActivity) -> some View {
        HStack(spacing: 12) {
            avatar(for: activity)
            Text("@\(actorHandle(activity)) rated · event unavailable")
                .font(.deejMono(10))
                .foregroundStyle(.deejOrangeLow)
            Spacer()
            timestampText(activity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(cardBackground)
    }

    // MARK: header + avatar helpers
    private func header(activity: FeedActivity, verb: String, subject: String) -> some View {
        HStack(spacing: 10) {
            avatar(for: activity)
            HStack(spacing: 8) {
                Text("@\(actorHandle(activity))")
                    .font(.deejMono(13, weight: .bold))
                    .foregroundStyle(.deejCream)
                    .deejTracking(0.5)
                Text(verb)
                    .font(.deejMono(11, weight: .medium))
                    .foregroundStyle(.deejOrangeLow)
                Text(subject)
                    .font(.deejMono(13, weight: .bold))
                    .foregroundStyle(.deejOrangeHigh)
                    .deejTracking(0.5)
            }
            Spacer(minLength: 4)
            timestampText(activity)
        }
    }

    private func avatar(for activity: FeedActivity) -> some View {
        let isSelf = activity.userId == services.userId
        let handle = actorHandle(activity)
        let initials = String(handle.prefix(2).uppercased())
        return ZStack {
            Circle().fill(Color.deejButtonDark)
                .overlay {
                    Circle().strokeBorder(isSelf ? Color.deejOrangePrimary : Color.deejOrangeLow,
                                          lineWidth: isSelf ? 1.5 : 1)
                }
            Text(initials)
                .font(.deejMono(11, weight: .bold))
                .foregroundStyle(isSelf ? Color.deejOrangeHigh : Color.deejOrangeMid)
        }
        .frame(width: 36, height: 36)
    }

    private func actorHandle(_ activity: FeedActivity) -> String {
        services.actor(for: activity)?.username ?? "unknown"
    }

    private func footerTag(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.deejMono(9, weight: .semibold))
            .foregroundStyle(tint)
            .deejTracking(1.2)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.deejBgPanel)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.deejBgPanelEdge, lineWidth: 1)
            }
    }

    private func timestampText(_ activity: FeedActivity) -> some View {
        Text(relativeTime(from: activity.createdAt))
            .font(.deejMono(9, weight: .semibold))
            .foregroundStyle(.deejTextFaint)
            .deejTracking(1.2)
    }

    private func relativeTime(from date: Date) -> String {
        let interval = Date.now.timeIntervalSince(date)
        switch interval {
        case ..<60:      return "NOW"
        case ..<3600:    return "\(Int(interval / 60))M"
        case ..<86_400:  return "\(Int(interval / 3600))H"
        case ..<604_800: return "\(Int(interval / 86_400))D"
        default:         return "\(Int(interval / 604_800))W"
        }
    }
}

#Preview {
    FeedView()
        .environment(AppServices())
        .preferredColorScheme(.dark)
}
