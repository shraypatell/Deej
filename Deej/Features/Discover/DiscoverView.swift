//
//  DiscoverView.swift
//  Phase 6 wires up MapKit. For Phase 3 this is a placeholder.
//

import SwiftUI

struct DiscoverView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("DISCOVER")
                .font(.deejMono(28, weight: .bold))
                .foregroundStyle(.deejCream)
            Text("radar map + near-you list lands in phase 6")
                .font(.deejMono(11))
                .foregroundStyle(.deejOrangeLow)
                .deejTracking(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DiscoverView().background(Color.deejBgCanvas)
}
