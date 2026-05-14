//
//  Typography.swift
//  Mono-first typography for Deej.
//
//  v1: system monospaced (SF Mono) — zero bundle weight, ships immediately.
//  v1.1: swap to bundled JetBrains Mono + Caveat (OFL licensed).
//

import SwiftUI

extension Font {
    /// Monospaced font used for all hardware/CRT typography.
    static func deejMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Handwritten/marker accent used on cassette card artist names.
    static func deejMarker(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif).italic()
    }
}

extension View {
    /// Convenience wrapper for letter-spacing in points.
    func deejTracking(_ value: CGFloat) -> some View {
        self.tracking(value)
    }
}
