//
//  FeedView.swift
//  Phase 5 wires up real activity. For Phase 3 this is a placeholder.
//

import SwiftUI

struct FeedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("FEED")
                .font(.deejMono(28, weight: .bold))
                .foregroundStyle(.deejCream)
            Text("social activity stream lands in phase 5")
                .font(.deejMono(11))
                .foregroundStyle(.deejOrangeLow)
                .deejTracking(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FeedView().background(Color.deejBgCanvas)
}
