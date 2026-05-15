//
//  CRTScreen.swift
//  Dark orange-phosphor screen with grid overlay, soft top glow, and inner shadow.
//  Used as the data-display area inside HardwarePanel.
//

import SwiftUI

struct CRTScreen<Content: View>: View {
    var cornerRadius: CGFloat = 8
    var showsGrid: Bool = true
    var showsGlow: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.deejBgScreen)
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(Color.deejBgScreenEdge, lineWidth: 1)
                        }
                    if showsGlow { glowLayer }
                    if showsGrid { gridLayer }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.7), radius: 6, y: 2)
            }
    }

    // Radial orange wash from upper-center, faking CRT phosphor glow.
    private var glowLayer: some View {
        Ellipse()
            .fill(RadialGradient(
                colors: [Color.deejOrangePrimary.opacity(0.12), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 240))
            .blendMode(.plusLighter)
            .opacity(0.7)
            .allowsHitTesting(false)
    }

    // 4×4 grid, intentionally faint so it whispers rather than shouts.
    private var gridLayer: some View {
        Canvas { context, size in
            let cols = 5, rows = 5
            let stepX = size.width / CGFloat(cols)
            let stepY = size.height / CGFloat(rows)
            for i in 1..<cols {
                let x = stepX * CGFloat(i)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(Color.deejOrangeTrack.opacity(0.55)), lineWidth: 1)
            }
            for i in 1..<rows {
                let y = stepY * CGFloat(i)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Color.deejOrangeTrack.opacity(0.55)), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    CRTScreen {
        Text("CRT")
            .font(.deejMono(28, weight: .bold))
            .foregroundStyle(.deejOrangeHigh)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(width: 320, height: 420)
    .padding()
    .background(Color.deejBgCanvas)
}
