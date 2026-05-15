//
//  CassetteCard.swift
//  Cream-label cassette graphic — used as the hero on Event Detail and as a
//  mini-preview on the Feed activity cards. Full and mini variants.
//

import SwiftUI

struct CassetteCard: View {
    enum Style { case full, mini }

    let event: Event
    let log: EventLog?
    var sideLabel: String = "A"
    var style: Style = .full

    var body: some View {
        switch style {
        case .full: fullVariant
        case .mini: miniVariant
        }
    }

    // MARK: full
    private var fullVariant: some View {
        ZStack {
            cassetteBackground

            VStack(alignment: .leading, spacing: 0) {
                topRow
                    .padding(.top, 14)
                    .padding(.horizontal, 16)

                Text(event.artistName)
                    .font(.deejMarker(34))
                    .foregroundStyle(Color(red: 0.09, green: 0.16, blue: 0.42))
                    .padding(.leading, 16)
                    .padding(.top, 4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                ruleLine.padding(.top, 8)

                oledRow.padding(.top, 12).padding(.horizontal, 16)

                Spacer(minLength: 0)

                ruleLine.padding(.top, 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("BOOTLEG · \(event.venueName) · \(event.city ?? "")")
                        .font(.deejMono(10, weight: .semibold))
                        .foregroundStyle(Color(red: 0.04, green: 0.04, blue: 0.03))
                    Text(handwrittenDateLine)
                        .font(.deejMono(10, weight: .medium))
                        .foregroundStyle(Color(red: 0.35, green: 0.33, blue: 0.28))
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                HStack(spacing: 22) {
                    cassetteHole
                    cassetteHole
                    cassetteHole
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
        }
        .frame(height: 232)
    }

    private var miniVariant: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ARTIST / VENUE")
                    .font(.deejMono(7, weight: .semibold))
                    .foregroundStyle(Color(red: 0.48, green: 0.45, blue: 0.41))
                    .deejTracking(1.5)
                Text(event.artistName)
                    .font(.deejMarker(20))
                    .foregroundStyle(Color(red: 0.09, green: 0.16, blue: 0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(event.venueName) · \(shortDate(event.eventDate))")
                    .font(.deejMono(8))
                    .foregroundStyle(Color(red: 0.35, green: 0.33, blue: 0.28))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)

            if let log {
                miniOLED(score: log.aggregateScore)
                    .padding(.trailing, 10)
            }
        }
        .frame(height: 72)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.deejCream)
                .shadow(color: .black.opacity(0.4), radius: 8, y: 2)
        }
    }

    private func miniOLED(score: Double) -> some View {
        VStack(spacing: 0) {
            Text("SCORE")
                .font(.deejMono(6, weight: .semibold))
                .foregroundStyle(Color(red: 0.48, green: 0.45, blue: 0.41))
                .deejTracking(1.5)
            Text(score.formatted(.number.precision(.fractionLength(1))))
                .font(.deejMono(22, weight: .bold))
                .foregroundStyle(.deejOrangeHigh)
        }
        .frame(width: 76, height: 56)
        .background {
            Capsule()
                .fill(Color.deejBgScreen)
                .overlay { Capsule().strokeBorder(.black, lineWidth: 1) }
        }
    }

    // MARK: full helpers
    private var cassetteBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.deejCream)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(red: 0.75, green: 0.72, blue: 0.66), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.5), radius: 16, y: 4)
    }

    private var topRow: some View {
        HStack {
            Text("ARTIST / DATE")
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(Color(red: 0.48, green: 0.45, blue: 0.41))
                .deejTracking(1.5)
            Spacer()
            Text("SIDE")
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(Color(red: 0.48, green: 0.45, blue: 0.41))
                .deejTracking(1.5)
            Text(sideLabel)
                .font(.deejMono(24, weight: .heavy))
                .foregroundStyle(Color(red: 0.04, green: 0.04, blue: 0.03))
        }
    }

    private var ruleLine: some View {
        Rectangle()
            .fill(Color(red: 0.75, green: 0.72, blue: 0.66))
            .frame(height: 1)
            .opacity(0.5)
    }

    private var oledRow: some View {
        HStack(spacing: 14) {
            reel
            OLEDDisplay(cornerRadius: 35) {
                HStack(spacing: 0) {
                    oledStat(label: "LOG", value: "\(logIndexString)", tint: .deejCream)
                    oledStat(label: "FRND", value: "00", tint: .deejCream)
                    oledStat(label: "SCR", value: scoreString, tint: .deejOrangeHigh)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 70)
            reel
        }
    }

    private func oledStat(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(.deejCreamDim)
                .deejTracking(1.5)
            Text(value)
                .font(.deejMono(24, weight: .bold))
                .foregroundStyle(tint)
                .deejTracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var reel: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.48, green: 0.45, blue: 0.41))
                .frame(width: 14, height: 14)
                .overlay { Circle().strokeBorder(Color(red: 0.36, green: 0.33, blue: 0.28), lineWidth: 1) }
                .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
            Circle()
                .fill(Color(red: 0.22, green: 0.20, blue: 0.16))
                .frame(width: 4, height: 4)
        }
    }

    private var cassetteHole: some View {
        Circle()
            .fill(Color(red: 0.22, green: 0.20, blue: 0.16))
            .frame(width: 6, height: 6)
    }

    private var handwrittenDateLine: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd · EEE · HH:mm"
        return f.string(from: event.eventDate).uppercased() + " · LIVE_SET"
    }

    private var logIndexString: String {
        // Placeholder until we have real log numbering.
        guard let log else { return "—" }
        return String(format: "%03d", abs(log.id.uuidString.hashValue) % 1000)
    }

    private var scoreString: String {
        guard let log else { return "—" }
        return String(format: "%.1f", log.aggregateScore)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM.dd"
        return f.string(from: date)
    }
}

#Preview {
    let store = LocalEventStore()
    let event = store.suggestedEvents.first!
    let log = EventLog(
        id: UUID(), userId: UUID(), eventId: event.id,
        ratingArtistPerformance: 9, ratingCrowdEnergy: 8, ratingVenue: 7,
        ratingLightingVisuals: 9, ratingMusicSelection: 8, ratingAtmosphereVibe: 9, ratingValue: 7,
        aggregateScore: 8.2, notes: nil, photoURLs: [],
        status: .active, createdAt: .now, updatedAt: .now)
    return VStack(spacing: 24) {
        CassetteCard(event: event, log: log, style: .full)
        CassetteCard(event: event, log: log, style: .mini)
    }
    .padding(20)
    .background(Color.deejBgPanel)
}
