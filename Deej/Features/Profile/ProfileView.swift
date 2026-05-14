//
//  ProfileView.swift
//  Phase 5 implements the real profile (own + other variants).
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("PROFILE")
                .font(.deejMono(28, weight: .bold))
                .foregroundStyle(.deejCream)
            Text("taste profile + friends land in phase 5")
                .font(.deejMono(11))
                .foregroundStyle(.deejOrangeLow)
                .deejTracking(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ProfileView().background(Color.deejBgCanvas)
}
