//
//  HardwareButton.swift
//  Custom ButtonStyle used across the hardware-aesthetic surfaces.
//  Three variants — primary (orange glowing), secondary (dark/orange text),
//  ghost (dark/dim text for archive/undo).
//

import SwiftUI

struct HardwareButtonStyle: ButtonStyle {
    enum Variant: Sendable { case primary, secondary, ghost, destructive }

    let variant: Variant
    var cornerRadius: CGFloat = 6

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .foregroundStyle(textColor)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(bgColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(strokeColor, lineWidth: 1)
                    }
                    .shadow(color: glowColor, radius: pressed ? 4 : 10, y: pressed ? 1 : 2)
            }
            .scaleEffect(pressed ? 0.97 : 1)
            .animation(.spring(duration: 0.18), value: pressed)
    }

    // MARK: variant tokens
    private var bgColor: Color {
        switch variant {
        case .primary:     .deejOrangePrimary
        case .secondary:   .deejButtonDark
        case .ghost:       .deejButtonDark
        case .destructive: .deejButtonDark
        }
    }

    private var strokeColor: Color {
        switch variant {
        case .primary:     .deejOrangeBright
        case .secondary:   .deejBgPanelEdge
        case .ghost:       .deejBgPanelEdge
        case .destructive: .deejStatusRed.opacity(0.6)
        }
    }

    private var textColor: Color {
        switch variant {
        case .primary:     .deejBgScreen
        case .secondary:   .deejOrangeHigh
        case .ghost:       .deejTextFaint
        case .destructive: .deejStatusRed
        }
    }

    private var glowColor: Color {
        switch variant {
        case .primary:     Color.deejOrangePrimary.opacity(0.5)
        case .secondary:   .clear
        case .ghost:       .clear
        case .destructive: Color.deejStatusRed.opacity(0.25)
        }
    }
}

extension ButtonStyle where Self == HardwareButtonStyle {
    static func hardware(_ variant: HardwareButtonStyle.Variant = .primary) -> HardwareButtonStyle {
        HardwareButtonStyle(variant: variant)
    }
}

#Preview {
    VStack(spacing: 14) {
        Button("LOG_EVENT")     { }.buttonStyle(.hardware(.primary))
        Button("SHARE")         { }.buttonStyle(.hardware(.secondary))
        Button("↶ UNDO")        { }.buttonStyle(.hardware(.ghost))
        Button("DELETE")        { }.buttonStyle(.hardware(.destructive))
    }
    .font(.deejMono(13, weight: .bold))
    .padding(24)
    .background(Color.deejBgCanvas)
}
