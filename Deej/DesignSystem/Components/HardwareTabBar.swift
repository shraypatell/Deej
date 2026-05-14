//
//  HardwareTabBar.swift
//  Five-tab bottom navigation with a glowing center action button.
//

import SwiftUI

struct HardwareTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 8) {
            tab(.feed,     icon: "house.fill",                       label: "FEED")
            tab(.discover, icon: "dot.radiowaves.left.and.right",    label: "DISCOVER")
            centerLogButton
            tab(.attended, icon: "list.bullet",                      label: "ATTENDED")
            tab(.me,       icon: "person.fill",                      label: "ME")
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background {
            Color.deejBgCanvas
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.deejBgPanelEdge)
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func tab(_ kind: AppTab, icon: String, label: String) -> some View {
        let active = selection == kind
        return Button {
            selection = kind
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 19))
                    .frame(width: 22, height: 22)
                Text(label)
                    .font(.deejMono(label.count > 4 ? 7 : 8, weight: active ? .bold : .semibold))
                    .deejTracking(label.count > 4 ? 0.8 : 1.2)
            }
            .foregroundStyle(active ? Color.deejOrangeHigh : Color.deejTextFaint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.deejButtonDark)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(active ? Color.deejOrangePrimary : Color.deejBgPanelEdge,
                                    lineWidth: 1)
                    }
                    .shadow(color: active ? Color.deejOrangePrimary.opacity(0.4) : .clear,
                            radius: 8)
            }
        }
        .buttonStyle(.plain)
    }

    private var centerLogButton: some View {
        Button {
            selection = .log
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(Color.deejBgScreen)
                .frame(width: 70, height: 70)
                .background {
                    Circle()
                        .fill(Color.deejOrangePrimary)
                        .overlay {
                            Circle().stroke(Color.deejOrangeBright, lineWidth: 1.5)
                        }
                        .shadow(color: Color.deejOrangePrimary.opacity(0.55),
                                radius: 16, y: 3)
                }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HardwareTabBarPreview()
}

private struct HardwareTabBarPreview: View {
    @State private var selection: AppTab = .discover
    var body: some View {
        VStack {
            Spacer()
            HardwareTabBar(selection: $selection)
        }
        .background(Color.deejBgCanvas)
    }
}
