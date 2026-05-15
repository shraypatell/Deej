//
//  DimensionSlider.swift
//  Horizontal 1–10 slider with focus state, tap-to-focus, and drag-to-set.
//  The focused row is brighter, has a thicker track, and shows a glowing handle.
//

import SwiftUI

struct DimensionSlider: View {
    let label: String
    @Binding var value: Int
    var isFocused: Bool = false
    var onFocus: () -> Void = {}

    private let range: ClosedRange<Int> = 1...10

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.deejMono(8, weight: isFocused ? .bold : .medium))
                .foregroundStyle(isFocused ? Color.deejOrangeHigh : Color.deejOrangeLow)
                .deejTracking(0.4)
                .frame(width: 124, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            track

            Text(value.formatted(.number.precision(.fractionLength(1))))
                .font(.deejMono(11, weight: .bold))
                .foregroundStyle(isFocused ? Color.deejOrangeHigh : Color.deejOrangeMid)
                .deejTracking(0.5)
                .frame(width: 32, alignment: .trailing)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.snappy(duration: 0.18), value: value)
        }
        .frame(height: 26)
        .contentShape(Rectangle())
        .onTapGesture { onFocus() }
    }

    private var track: some View {
        GeometryReader { geo in
            let span = max(range.upperBound - range.lowerBound, 1)
            let progress = CGFloat(value - range.lowerBound) / CGFloat(span)
            let activeWidth = geo.size.width * progress
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.deejOrangeTrack)
                    .frame(height: isFocused ? 4 : 2)
                Capsule()
                    .fill(isFocused ? Color.deejOrangeBright : Color.deejOrangeDeep)
                    .frame(width: activeWidth, height: isFocused ? 4 : 2)
                    .animation(.snappy(duration: 0.2), value: activeWidth)
                if isFocused {
                    Circle()
                        .fill(Color.deejOrangeHigh)
                        .frame(width: 12, height: 12)
                        .shadow(color: Color.deejOrangePrimary, radius: 6)
                        .offset(x: max(0, activeWidth - 6))
                        .animation(.snappy(duration: 0.2), value: activeWidth)
                }
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(trackDragGesture(width: geo.size.width))
        }
        .frame(height: 18)
    }

    private func trackDragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                if !isFocused { onFocus() }
                guard width > 0 else { return }
                let fraction = max(0, min(1, drag.location.x / width))
                let span = range.upperBound - range.lowerBound
                let newValue = range.lowerBound + Int((fraction * CGFloat(span)).rounded())
                if newValue != value { value = newValue }
            }
    }
}

#Preview {
    DimensionSliderPreview()
}

private struct DimensionSliderPreview: View {
    @State private var artistPerf = 8
    @State private var crowdEnergy = 9
    @State private var venueScore = 7
    @State private var focused: Dimension = .artistPerformance

    var body: some View {
        VStack(spacing: 12) {
            DimensionSlider(label: "ARTIST_PERFORMANCE",
                            value: $artistPerf,
                            isFocused: focused == .artistPerformance,
                            onFocus: { focused = .artistPerformance })
            DimensionSlider(label: "CROWD_ENERGY",
                            value: $crowdEnergy,
                            isFocused: focused == .crowdEnergy,
                            onFocus: { focused = .crowdEnergy })
            DimensionSlider(label: "VENUE",
                            value: $venueScore,
                            isFocused: focused == .venue,
                            onFocus: { focused = .venue })
        }
        .padding(24)
        .background(Color.deejBgScreen)
    }
}
