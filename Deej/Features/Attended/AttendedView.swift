//
//  AttendedView.swift
//  Phase 4 wires up the real log list. For Phase 3 this is a placeholder.
//

import SwiftUI

struct AttendedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("ATTENDED")
                .font(.deejMono(28, weight: .bold))
                .foregroundStyle(.deejCream)
            Text("your event archive lands in phase 4")
                .font(.deejMono(11))
                .foregroundStyle(.deejOrangeLow)
                .deejTracking(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AttendedView().background(Color.deejBgCanvas)
}
