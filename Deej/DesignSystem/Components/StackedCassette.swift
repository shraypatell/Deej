//
//  StackedCassette.swift
//  Cassette-tape row designed for the Attended list — meant to read like
//  one tape in a vertical pile. Cream label band across the middle (same
//  color as CassetteCard's full variant), handwritten artist name on the
//  band, and the rating in an OLED-style readout on the right.
//
//  Stacking effect is produced by giving each cassette a slight downward
//  shadow + a thin spine strip below the body so the next tape's edge
//  peeks out underneath. Used inside a VStack with negative spacing.
//

import SwiftUI

struct StackedCassette: View {
    let event: Event
    let log: EventLog
    /// Position in the stack (0 = top). Slightly modulates rotation/shadow
    /// so the pile feels organic instead of machine-stamped.
    var depth: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            tapeSpine                  // dark stripe peeking out under the body
            cassetteBody
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }

    // MARK: body
    private var cassetteBody: some View {
        HStack(spacing: 0) {
            // Cream label section
            ZStack(alignment: .topLeading) {
                Color.deejCream
                VStack(alignment: .leading, spacing: 0) {
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
                    .padding(.top, 8)
                    .padding(.horizontal, 12)

                    Text(event.artistName)
                        .font(.deejMarker(22))
                        .foregroundStyle(Color(red: 0.09, green: 0.16, blue: 0.42))
                        .padding(.leading, 12)
                        .padding(.top, 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text("\(event.venueName) · \(shortDate(event.eventDate))")
                        .font(.deejMono(8, weight: .medium))
                        .foregroundStyle(Color(red: 0.35, green: 0.33, blue: 0.28))
                        .padding(.leading, 12)
                        .padding(.top, 2)
                        .padding(.bottom, 8)
                        .lineLimit(1)
                }
            }

            // Score OLED readout
            oledScore
                .padding(.trailing, 10)
                .padding(.vertical, 8)
        }
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.deejCream)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color(red: 0.75, green: 0.72, blue: 0.66), lineWidth: 1)
                }
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 14) {
                cassetteHole; cassetteHole; cassetteHole
            }
            .padding(.bottom, 4)
        }
        .shadow(color: .black.opacity(0.45), radius: 6, y: 3)
        .rotationEffect(.degrees(rotationJitter), anchor: .center)
        .padding(.bottom, 8) // makes room for the tape spine peek
    }

    // MARK: spine
    private var tapeSpine: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(red: 0.16, green: 0.14, blue: 0.12))
            .frame(height: 14)
            .padding(.horizontal, 18)
            .offset(y: 0)
            .opacity(0.85)
    }

    // MARK: OLED
    private var oledScore: some View {
        VStack(spacing: 0) {
            Text("SCORE")
                .font(.deejMono(6, weight: .semibold))
                .foregroundStyle(Color(red: 0.48, green: 0.45, blue: 0.41))
                .deejTracking(1.5)
                .padding(.top, 2)
            Text(log.aggregateScore.formatted(.number.precision(.fractionLength(1))))
                .font(.deejMono(22, weight: .bold))
                .foregroundStyle(scoreTint)
                .padding(.top, 1)
        }
        .frame(width: 72)
        .frame(maxHeight: .infinity)
        .background {
            Capsule()
                .fill(Color.deejBgScreen)
                .overlay { Capsule().strokeBorder(.black, lineWidth: 1) }
        }
    }

    private var cassetteHole: some View {
        Circle()
            .fill(Color(red: 0.22, green: 0.20, blue: 0.16))
            .frame(width: 4, height: 4)
    }

    // MARK: derived
    private var scoreTint: Color {
        switch log.aggregateScore {
        case 9...:  return .deejOrangeHigh
        case 7..<9: return .deejOrangeBright
        case 5..<7: return .deejOrangeMid
        default:    return .deejOrangeLow
        }
    }

    private var sideLabel: String {
        // Use a stable per-event "side" letter so individual cassettes feel
        // distinct in the pile but the same event always renders the same.
        let alphabet = Array("ABCD")
        return String(alphabet[abs(event.id.uuidString.hashValue) % alphabet.count])
    }

    private var monthYearStamp: String {
        let f = DateFormatter()
        f.dateFormat = "MMM ''yy"
        return f.string(from: event.eventDate).uppercased()
    }

    private var rotationJitter: Double {
        // Small alternating tilt: ±0.6°, deterministic on depth.
        depth % 2 == 0 ? -0.4 : 0.4
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
    return VStack(spacing: -4) {
        StackedCassette(event: event, log: log1, depth: 0)
        StackedCassette(event: event2, log: log2, depth: 1)
        StackedCassette(event: event, log: log1, depth: 2)
    }
    .padding(20)
    .background(Color.deejBgCanvas)
}
