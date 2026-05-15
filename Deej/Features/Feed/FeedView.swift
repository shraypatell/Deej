//
//  FeedView.swift
//  Social activity stream. Phase 5.5 renders mocked friend activity using
//  mini CassetteCard previews. Phase 5.6 swaps the mock data for a query
//  on `activity_feed` joined with friends.
//

import SwiftUI

struct FeedView: View {
    @Environment(AppServices.self) private var services

    var body: some View {
        VStack(spacing: 0) {
            navHeader
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(mockFeedItems) { item in
                        feedCard(for: item)
                    }
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .background(Color.deejBgCanvas.ignoresSafeArea())
    }

    // MARK: nav
    private var navHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ACTIVITY · 0_FRIENDS")
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
            roundIcon("line.3.horizontal.decrease")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var livePill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.deejStatusGreen)
                .frame(width: 5, height: 5)
            Text("LIVE")
                .font(.deejMono(8, weight: .bold))
                .foregroundStyle(.deejStatusGreen)
                .deejTracking(1.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(Color.deejButtonDark)
                .overlay { Capsule().strokeBorder(Color.deejBgPanelEdge, lineWidth: 1) }
        }
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

    // MARK: card switcher
    @ViewBuilder
    private func feedCard(for item: FeedItem) -> some View {
        switch item.kind {
        case .ratedEvent(let event, let log, let likes, let comments):
            ratedCard(item: item, event: event, log: log, likes: likes, comments: comments)
        case .milestone(let badge, let blurb):
            milestoneCard(item: item, badge: badge, blurb: blurb)
        }
    }

    // MARK: rated_event variant
    private func ratedCard(item: FeedItem, event: Event, log: EventLog, likes: Int, comments: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            header(item: item, verb: "rated", subject: event.artistName)
            CassetteCard(event: event, log: log, style: .mini)
            HStack(spacing: 14) {
                footerTag("♥ \(likes) FRIENDS",   tint: .deejCreamDim)
                footerTag("▢ \(comments) COMMENTS", tint: .deejOrangeLow)
                footerTag("↗ SHARE",                 tint: .deejOrangeLow)
                Spacer()
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.deejBgPanel)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.deejBgPanelEdge, lineWidth: 1)
                }
        }
    }

    // MARK: milestone variant
    private func milestoneCard(item: FeedItem, badge: String, blurb: String) -> some View {
        HStack(spacing: 12) {
            avatar(item: item)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("@\(item.actorHandle)")
                        .font(.deejMono(12, weight: .bold))
                        .foregroundStyle(.deejCream)
                    Text("unlocked")
                        .font(.deejMono(11, weight: .medium))
                        .foregroundStyle(.deejOrangeLow)
                    Text(badge)
                        .font(.deejMono(12, weight: .bold))
                        .foregroundStyle(.deejStatusGreen)
                        .deejTracking(0.5)
                }
                Text(blurb)
                    .font(.deejMono(9, weight: .medium))
                    .foregroundStyle(.deejOrangeLow)
                    .deejTracking(0.5)
            }
            Spacer()
            Text(item.timeAgo)
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(.deejTextFaint)
                .deejTracking(1.2)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.deejBgPanel)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.deejBgPanelEdge, lineWidth: 1)
                }
        }
    }

    // MARK: shared header
    private func header(item: FeedItem, verb: String, subject: String) -> some View {
        HStack(spacing: 10) {
            avatar(item: item)
            HStack(spacing: 8) {
                Text("@\(item.actorHandle)")
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
            Text(item.timeAgo)
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(.deejTextFaint)
                .deejTracking(1.2)
        }
    }

    private func avatar(item: FeedItem) -> some View {
        ZStack {
            Circle()
                .fill(Color.deejButtonDark)
                .overlay {
                    Circle().strokeBorder(item.isClose ? Color.deejOrangePrimary : Color.deejOrangeLow,
                                          lineWidth: item.isClose ? 1.5 : 1)
                }
            Text(item.actorInitials)
                .font(.deejMono(11, weight: .bold))
                .foregroundStyle(item.isClose ? Color.deejOrangeHigh : Color.deejOrangeMid)
        }
        .frame(width: 36, height: 36)
    }

    private func footerTag(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.deejMono(9, weight: .semibold))
            .foregroundStyle(tint)
            .deejTracking(1.2)
    }

    // MARK: mock data
    /// Three illustrative feed items hardcoded for Phase 5.5.
    /// Replaced by a real query against `activity_feed` in Phase 5.6.
    private var mockFeedItems: [FeedItem] {
        let now = Date()
        let cal = Calendar.current

        let event1 = Event(
            id: UUID(), artistName: "@FOUR_TET", venueName: "KNOCKDOWN_CENTER",
            city: "BKLYN",
            eventDate: cal.date(byAdding: .day, value: -3, to: now) ?? now,
            startTime: nil, promotedByUserId: nil, createdAt: now)
        let log1 = EventLog(
            id: UUID(), userId: UUID(), eventId: event1.id,
            ratingArtistPerformance: 9, ratingCrowdEnergy: 10, ratingVenue: 8,
            ratingLightingVisuals: 9, ratingMusicSelection: 9, ratingAtmosphereVibe: 10, ratingValue: 9,
            aggregateScore: 9.1, notes: nil, photoURLs: [],
            status: .active, createdAt: now, updatedAt: now)

        let event2 = Event(
            id: UUID(), artistName: "@CARIBOU", venueName: "ELSEWHERE",
            city: "BSHWK",
            eventDate: cal.date(byAdding: .day, value: -5, to: now) ?? now,
            startTime: nil, promotedByUserId: nil, createdAt: now)
        let log2 = EventLog(
            id: UUID(), userId: UUID(), eventId: event2.id,
            ratingArtistPerformance: 7, ratingCrowdEnergy: 8, ratingVenue: 7,
            ratingLightingVisuals: 7, ratingMusicSelection: 8, ratingAtmosphereVibe: 7, ratingValue: 8,
            aggregateScore: 7.5, notes: nil, photoURLs: [],
            status: .active, createdAt: now, updatedAt: now)

        return [
            FeedItem(actorHandle: "JM_BKLYN", actorInitials: "JM", timeAgo: "2H",
                     isClose: true,
                     kind: .ratedEvent(event: event1, log: log1, likes: 4, comments: 2)),
            FeedItem(actorHandle: "ava.eth", actorInitials: "AV", timeAgo: "5H",
                     isClose: false,
                     kind: .ratedEvent(event: event2, log: log2, likes: 2, comments: 1)),
            FeedItem(actorHandle: "SK_NYC", actorInitials: "SK", timeAgo: "8H",
                     isClose: false,
                     kind: .milestone(badge: "50_LOGS_BADGE",
                                       blurb: "milestone reached · 50 events archived"))
        ]
    }
}

// MARK: model
private struct FeedItem: Identifiable {
    enum Kind {
        case ratedEvent(event: Event, log: EventLog, likes: Int, comments: Int)
        case milestone(badge: String, blurb: String)
    }
    let id = UUID()
    let actorHandle: String
    let actorInitials: String
    let timeAgo: String
    let isClose: Bool
    let kind: Kind
}

#Preview {
    FeedView()
        .environment(AppServices())
        .preferredColorScheme(.dark)
}
