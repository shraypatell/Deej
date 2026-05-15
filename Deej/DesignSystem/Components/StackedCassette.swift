//
//  StackedCassette.swift
//  VHS-style tape rendered for the Attended pile: dark `#1A1A1C` cassette
//  body with a cream sticker label stretched across the middle; the
//  artist name is written in blue marker on the sticker; the score sits
//  on the right dark portion of the body as an engraved cream readout.
//
//  Stacks render with `spacing: 0` — each cassette has a 2pt dark bottom
//  edge that becomes the visible spine of the next tape underneath.
//

import SwiftUI

struct StackedCassette: View {
    let event: Event
    let log: EventLog

    private let height: CGFloat = 96

    var body: some View {
        ZStack(alignment: .bottom) {
            cassetteBody
            spoolHoles
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }

    // MARK: shell
    private var cassetteBody: some View {
        ZStack {
            // Dark plastic body
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.deejBgPanel)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.deejBgPanelEdge, lineWidth: 1)
                }

            // Faux glossy highlight at the top — subtle shine
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.07), .clear],
                    startPoint: .top, endPoint: .center))
                .padding(.horizontal, 4)
                .padding(.top, 2)
                .allowsHitTesting(false)

            // The two main columns: cream sticker label (left ~70%) + score on dark (right ~30%)
            HStack(spacing: 0) {
                stickerLabel
                    .padding(.leading, 10)
                    .padding(.trailing, 4)
                scoreColumn
                    .padding(.trailing, 12)
            }
            .padding(.vertical, 10)

            // Bottom-of-cassette dark seam → reads as the spine of the next tape underneath
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(height: 2)
                    .padding(.horizontal, 6)
            }
        }
        .shadow(color: .black.opacity(0.55), radius: 4, y: 3)
    }

    // MARK: sticker (cream label)
    private var stickerLabel: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.deejCream)
                .overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Color(red: 0.78, green: 0.74, blue: 0.66), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.25), radius: 1, y: 1)

            VStack(alignment: .leading, spacing: 1) {
                // Top chrome row
                HStack {
                    Text("SIDE / \(sideLabel)")
                        .font(.deejMono(7, weight: .semibold))
                        .foregroundStyle(Color(red: 0.48, green: 0.45, blue: 0.41))
                        .deejTracking(1.5)
                    Spacer()
                    Text(monthYearStamp)
                        .font(.deejMono(7, weight: .semibold))
                        .foregroundStyle(Color(red: 0.48, green: 0.45, blue: 0.41))
                        .deejTracking(1.5)
                }
                .padding(.top, 6)

                // Marker artist name — blue ink
                Text(event.artistName)
                    .font(.deejMarker(22))
                    .foregroundStyle(Color(red: 0.09, green: 0.16, blue: 0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 0)

                // Venue · date in handwritten-style mono
                Text("\(event.venueName) · \(shortDate(event.eventDate))")
                    .font(.deejMono(8, weight: .medium))
                    .foregroundStyle(Color(red: 0.35, green: 0.33, blue: 0.28))
                    .lineLimit(1)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
    }

    // MARK: engraved score (right dark area)
    private var scoreColumn: some View {
        VStack(spacing: 2) {
            Text("SCORE")
                .font(.deejMono(7, weight: .semibold))
                .foregroundStyle(Color.deejCreamDim)
                .deejTracking(1.5)
                .shadow(color: .black.opacity(0.7), radius: 0, x: 0, y: 1)
            Text(log.aggregateScore.formatted(.number.precision(.fractionLength(1))))
                .font(.deejMono(22, weight: .bold))
                .foregroundStyle(scoreTint)
                .shadow(color: .black.opacity(0.7), radius: 0, x: 0, y: 1)
        }
        .frame(width: 64)
        .frame(maxHeight: .infinity)
    }

    // MARK: spool dots at bottom
    private var spoolHoles: some View {
        HStack(spacing: 12) {
            cassetteHole
            cassetteHole
            cassetteHole
        }
        .padding(.bottom, 5)
    }

    private var cassetteHole: some View {
        Circle()
            .fill(Color.black.opacity(0.65))
            .frame(width: 4, height: 4)
    }

    // MARK: derived
    private var scoreTint: Color {
        switch log.aggregateScore {
        case 9...:  return .deejOrangeHigh
        case 7..<9: return .deejOrangeBright
        case 5..<7: return .deejCream
        default:    return .deejCreamDim
        }
    }

    private var sideLabel: String {
        // Deterministic per-event letter — see "what does SIDE / X mean?" note.
        let alphabet = Array("ABCD")
        return String(alphabet[abs(event.id.uuidString.hashValue) % alphabet.count])
    }

    private var monthYearStamp: String {
        let f = DateFormatter()
        f.dateFormat = "MMM ''yy"
        return f.string(from: event.eventDate).uppercased()
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM.dd.yy"
        return f.string(from: date)
    }
}

#Preview {
    let event = Event(
        id: UUID(), artistName: "@FOUR_TET", venueName: "KNOCKDOWN_CENTER",
        city: "BKLYN", eventDate: .now, startTime: nil, promotedByUserId: nil, createdAt: .now)
    let log1 = EventLog(id: UUID(), userId: UUID(), eventId: event.id,
                       ratingArtistPerformance: 9, ratingCrowdEnergy: 10, ratingVenue: 8,
                       ratingLightingVisuals: 9, ratingMusicSelection: 9, ratingAtmosphereVibe: 10, ratingValue: 9,
                       aggregateScore: 9.1, notes: nil, photoURLs: [],
                       status: .active, createdAt: .now, updatedAt: .now)
    let event2 = Event(
        id: UUID(), artistName: "@CARIBOU", venueName: "ELSEWHERE",
        city: "BSHWK", eventDate: .now, startTime: nil, promotedByUserId: nil, createdAt: .now)
    let log2 = EventLog(id: UUID(), userId: UUID(), eventId: event2.id,
                       ratingArtistPerformance: 7, ratingCrowdEnergy: 8, ratingVenue: 7,
                       ratingLightingVisuals: 7, ratingMusicSelection: 8, ratingAtmosphereVibe: 7, ratingValue: 8,
                       aggregateScore: 7.5, notes: nil, photoURLs: [],
                       status: .active, createdAt: .now, updatedAt: .now)
    return VStack(spacing: 0) {
        StackedCassette(event: event, log: log1)
        StackedCassette(event: event2, log: log2)
        StackedCassette(event: event, log: log1)
    }
    .padding(20)
    .background(Color.deejBgCanvas)
}
