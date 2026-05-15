//
//  HardwarePanel.swift
//  The dark rounded device housing used as a frame around hero screens.
//  Has subtle inner highlight + outer drop shadow + 1pt edge stroke.
//

import SwiftUI

struct HardwarePanel<Content: View>: View {
    var cornerRadius: CGFloat = 24
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.deejBgPanel)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.deejBgPanelEdge, lineWidth: 1)
                    }
                    .overlay(alignment: .top) {
                        // 1pt warm highlight at the top edge (faux-bevel)
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Color.white.opacity(0.05), .clear],
                                startPoint: .top,
                                endPoint: .bottom))
                            .frame(height: 1)
                            .padding(.horizontal, 8)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 12)
            }
    }
}

#Preview {
    HardwarePanel {
        Text("DEVICE")
            .font(.deejMono(20, weight: .bold))
            .foregroundStyle(.deejCream)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(width: 320, height: 480)
    .padding()
    .background(Color.deejBgCanvas)
}
