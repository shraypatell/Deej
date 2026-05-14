//
//  StatusLED.swift
//  Small colored dot with optional glow + pulse.
//

import SwiftUI

struct StatusLED: View {
    enum State: Sendable { case ok, pending, awaiting, off }

    let state: State
    var size: CGFloat = 6
    var pulses: Bool = false

    @SwiftUI.State private var pulsePhase: CGFloat = 1.0

    var body: some View {
        let color = tint(for: state)
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(state == .off ? 0.25 : Double(pulsePhase))
            .shadow(color: state == .off ? .clear : color.opacity(0.9),
                    radius: 6, x: 0, y: 0)
            .onAppear {
                guard pulses, state == .awaiting else { return }
                withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                    pulsePhase = 0.45
                }
            }
    }

    private func tint(for state: State) -> Color {
        switch state {
        case .ok:       return .deejStatusGreen
        case .pending:  return .deejLEDAmber
        case .awaiting: return .deejStatusRed
        case .off:      return .deejTextFaint
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        StatusLED(state: .ok)
        StatusLED(state: .pending)
        StatusLED(state: .awaiting, pulses: true)
        StatusLED(state: .off)
    }
    .padding()
    .background(Color.deejBgCanvas)
}
