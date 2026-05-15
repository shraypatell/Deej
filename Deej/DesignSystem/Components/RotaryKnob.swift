//
//  RotaryKnob.swift
//  Physical knob with concentric grooves + LED position indicator.
//  Drag horizontally to change the value (10pt per unit). Knob rotates visually
//  on a 270° arc (value 1 → -135°, value 10 → +135°).
//

import SwiftUI

struct RotaryKnob: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...10
    var size: CGFloat = 160

    @State private var dragStartValue: Int?

    private var rotation: Angle {
        let span = max(range.upperBound - range.lowerBound, 1)
        let progress = Double(value - range.lowerBound) / Double(span)
        return .degrees(-135 + 270 * progress)
    }

    var body: some View {
        ZStack {
            shadow
            base
            grooves
            centerDot
            indicator
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(dragGesture)
        .accessibilityElement()
        .accessibilityLabel("Rotary knob")
        .accessibilityValue("\(value) of \(range.upperBound)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(range.upperBound, value + 1)
            case .decrement: value = max(range.lowerBound, value - 1)
            @unknown default: break
            }
        }
    }

    // MARK: layers
    private var shadow: some View {
        Circle()
            .fill(.black.opacity(0.55))
            .frame(width: size - 4, height: size - 4)
            .blur(radius: 14)
            .offset(y: 14)
    }

    private var base: some View {
        Circle()
            .fill(LinearGradient(
                colors: [Color(red: 0.94, green: 0.94, blue: 0.92),
                         Color(red: 0.75, green: 0.74, blue: 0.71)],
                startPoint: .top,
                endPoint: .bottom))
            .overlay {
                Circle().strokeBorder(.black.opacity(0.4), lineWidth: 1)
            }
    }

    private var grooves: some View {
        ForEach(0..<5, id: \.self) { i in
            let inset = CGFloat(10 + i * 10)
            Circle()
                .strokeBorder(.black.opacity(0.12 + Double(i) * 0.05), lineWidth: 0.8)
                .padding(inset)
        }
    }

    private var centerDot: some View {
        Circle()
            .fill(.black.opacity(0.35))
            .frame(width: 8, height: 8)
    }

    private var indicator: some View {
        Circle()
            .fill(Color.deejLEDAmber)
            .frame(width: 6, height: 6)
            .shadow(color: Color.deejOrangePrimary, radius: 10, x: 0, y: 0)
            .offset(y: -size / 2 + 12)
            .rotationEffect(rotation, anchor: .center)
            .animation(.snappy(duration: 0.2), value: value)
    }

    // MARK: drag
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                if dragStartValue == nil { dragStartValue = value }
                let dx = drag.translation.width
                let units = Int((dx / 12).rounded())
                let proposed = (dragStartValue ?? value) + units
                let clamped = max(range.lowerBound, min(range.upperBound, proposed))
                if clamped != value { value = clamped }
            }
            .onEnded { _ in dragStartValue = nil }
    }
}

#Preview {
    RotaryKnobPreview()
}

private struct RotaryKnobPreview: View {
    @State private var value: Int = 5
    var body: some View {
        VStack(spacing: 16) {
            RotaryKnob(value: $value)
            Text("\(value)")
                .font(.deejMono(36, weight: .bold))
                .foregroundStyle(.deejOrangeHigh)
        }
        .padding()
        .background(Color.deejBgPanel)
    }
}
