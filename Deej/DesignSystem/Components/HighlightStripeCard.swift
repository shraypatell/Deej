//
//  HighlightStripeCard.swift
//  Card with a glowing vertical stripe on the left edge. Used for
//  "BEST_MATCH" suggestions on Onboarding and "BEST_CAPTURE" cards on
//  Attended.
//

import SwiftUI

struct HighlightStripeCard<Content: View>: View {
    var tint: Color = .deejStatusGreen
    var cornerRadius: CGFloat = 12
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            // 18pt-wide stripe area; the actual stripe is a 3pt rectangle centered in it.
            ZStack {
                Color.clear
                Rectangle()
                    .fill(tint)
                    .frame(width: 3, height: 80)
                    .clipShape(Capsule())
                    .shadow(color: tint, radius: 8)
            }
            .frame(width: 18)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.deejBgPanel)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.deejBgPanelEdge, lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
        }
    }
}

#Preview {
    HighlightStripeCard {
        VStack(alignment: .leading, spacing: 4) {
            Text("● BEST_CAPTURE · OCT '24")
                .font(.deejMono(8, weight: .bold))
                .foregroundStyle(.deejStatusGreen)
                .deejTracking(1.2)
            Text("@BOYGENIUS")
                .font(.deejMono(20, weight: .bold))
                .foregroundStyle(.deejCream)
            Text("MSG · 2024.10.06 · SUN")
                .font(.deejMono(9))
                .foregroundStyle(.deejOrangeLow)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }
    .padding()
    .background(Color.deejBgCanvas)
}
