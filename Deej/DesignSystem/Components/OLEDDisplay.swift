//
//  OLEDDisplay.swift
//  Inset black readout — used inside the cassette stats panel (Event Detail)
//  and on Attended/Profile screens as small stat chips.
//

import SwiftUI

struct OLEDDisplay<Content: View>: View {
    var cornerRadius: CGFloat = 8
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.deejBgScreen)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.deejBgScreenEdge, lineWidth: 1)
                    }
                    .shadow(color: .white.opacity(0.08), radius: 0, y: 1)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
            }
    }
}

/// Compact 3-line readout — label tiny, value big — used as a stat chip on
/// Profile and Attended. The cassette OLED uses its own custom layout.
struct OLEDStatChip: View {
    let label: String
    let value: String
    var valueColor: Color = .deejOrangeHigh

    var body: some View {
        OLEDDisplay {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.deejMono(8, weight: .semibold))
                    .foregroundStyle(.deejCreamDim)
                    .deejTracking(1.5)
                Text(value)
                    .font(.deejMono(22, weight: .bold))
                    .foregroundStyle(valueColor)
                    .deejTracking(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        OLEDStatChip(label: "FRIENDS",   value: "24",   valueColor: .deejCream)
        OLEDStatChip(label: "LOGGED",    value: "247")
        OLEDStatChip(label: "AVG_SCORE", value: "7.82", valueColor: .deejOrangeBright)
    }
    .padding()
    .background(Color.deejBgCanvas)
}
