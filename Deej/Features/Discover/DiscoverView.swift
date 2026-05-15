//
//  DiscoverView.swift
//  Map of upcoming events near the user + a ranked "NEAREST" list below.
//  Phase 6: uses VenueCoordinates static lookup until we add real lat/lon
//  columns to the events table.
//

import CoreLocation
import MapKit
import SwiftUI

struct DiscoverView: View {
    @Environment(AppServices.self) private var services

    @State private var camera: MapCameraPosition = .region(.init(
        center: VenueCoordinates.defaultCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)))
    @State private var selectedEvent: Event?

    private var userCenter: CLLocationCoordinate2D { VenueCoordinates.defaultCenter }

    private var rankedEvents: [Event] {
        services.events
            .map { event -> (event: Event, miles: Double) in
                (event, VenueCoordinates.miles(from: userCenter,
                                               to: VenueCoordinates.coordinate(for: event)))
            }
            .sorted { $0.miles < $1.miles }
            .map(\.event)
    }

    var body: some View {
        VStack(spacing: 0) {
            navHeader
            mapBlock
            listBlock
        }
        .background(Color.deejBgCanvas.ignoresSafeArea())
        .sheet(item: $selectedEvent) { event in
            EventRankingView(event: event)
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.deejBgCanvas)
        }
    }

    // MARK: nav
    private var navHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("RADIUS · 5MI · BKLYN")
                    .font(.deejMono(8, weight: .semibold))
                    .foregroundStyle(.deejTextFaint)
                    .deejTracking(1.5)
                Text("DISCOVER")
                    .font(.deejMono(24, weight: .bold))
                    .foregroundStyle(.deejCream)
                    .deejTracking(0.5)
            }
            Spacer()
            scanningPill
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var scanningPill: some View {
        HStack(spacing: 6) {
            Circle().fill(.deejStatusGreen).frame(width: 5, height: 5)
            Text("SCANNING")
                .font(.deejMono(8, weight: .bold))
                .foregroundStyle(.deejStatusGreen)
                .deejTracking(1.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule().fill(Color.deejButtonDark)
                .overlay { Capsule().strokeBorder(Color.deejBgPanelEdge, lineWidth: 1) }
        }
    }

    // MARK: map
    private var mapBlock: some View {
        ZStack(alignment: .topLeading) {
            Map(position: $camera) {
                // User location marker (small cream dot, matches you-pin elsewhere).
                Annotation("", coordinate: userCenter) { youPin }
                    .annotationTitles(.hidden)

                // Event pins.
                ForEach(rankedEvents) { event in
                    Annotation(event.artistName,
                               coordinate: VenueCoordinates.coordinate(for: event)) {
                        eventPin(for: event)
                            .onTapGesture { selectedEvent = event }
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .mapControlVisibility(.hidden)
            .frame(maxWidth: .infinity)
            .frame(height: 360)

            cornerLabels
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14).strokeBorder(Color.deejBgPanelEdge, lineWidth: 1)
        }
        .padding(.horizontal, 16)
    }

    private var cornerLabels: some View {
        VStack {
            HStack {
                Text("LIVE_MAP")
                    .font(.deejMono(8, weight: .bold))
                    .foregroundStyle(.deejCreamDim)
                    .deejTracking(1.5)
                Spacer()
                Text("\(rankedEvents.count) DETECTED")
                    .font(.deejMono(8, weight: .bold))
                    .foregroundStyle(.deejOrangeHigh)
                    .deejTracking(1.5)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            Spacer()
            HStack {
                Spacer()
                Text("N ↑")
                    .font(.deejMono(10, weight: .bold))
                    .foregroundStyle(.deejOrangeHigh)
                    .padding(8)
                    .background {
                        Capsule().fill(Color.deejButtonDark.opacity(0.8))
                    }
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
            }
        }
        .allowsHitTesting(false)
    }

    private var youPin: some View {
        ZStack {
            Circle()
                .stroke(Color.deejCream, lineWidth: 1.5)
                .frame(width: 24, height: 24)
                .shadow(color: Color.deejCream.opacity(0.5), radius: 8)
            Circle().fill(.deejCream).frame(width: 8, height: 8)
        }
    }

    private func eventPin(for event: Event) -> some View {
        ZStack {
            Circle()
                .fill(Color.deejOrangePrimary.opacity(0.25))
                .frame(width: 22, height: 22)
            Circle()
                .fill(.deejOrangeHigh)
                .frame(width: 10, height: 10)
                .overlay { Circle().strokeBorder(Color.deejOrangePrimary, lineWidth: 1.5) }
                .shadow(color: Color.deejOrangePrimary, radius: 8)
        }
    }

    // MARK: list
    private var listBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("NEAREST_EVENTS")
                    .font(.deejMono(10, weight: .semibold))
                    .foregroundStyle(.deejCreamDim)
                    .deejTracking(1.5)
                Spacer()
                Text("↓ BY_DISTANCE")
                    .font(.deejMono(9, weight: .semibold))
                    .foregroundStyle(.deejOrangeLow)
                    .deejTracking(1.2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(rankedEvents.prefix(8).enumerated()), id: \.element.id) { idx, event in
                        Button { selectedEvent = event } label: {
                            row(event: event, isClosest: idx == 0)
                        }
                        .buttonStyle(.plain)
                        Rectangle().fill(Color.deejBgPanelEdge).frame(height: 1)
                    }
                    Spacer(minLength: 130)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func row(event: Event, isClosest: Bool) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isClosest ? Color.deejOrangeBright : .clear)
                .frame(width: 3, height: 38)
                .shadow(color: isClosest ? Color.deejOrangePrimary : .clear, radius: 6)
                .padding(.trailing, 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.artistName)
                    .font(.deejMono(13, weight: isClosest ? .bold : .semibold))
                    .foregroundStyle(isClosest ? Color.deejCream : Color.deejOrangeMid)
                    .deejTracking(0.5)
                Text("\(event.venueName) · \(shortDate(event.eventDate))")
                    .font(.deejMono(8))
                    .foregroundStyle(.deejOrangeLow)
                    .deejTracking(0.8)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(distanceString(for: event))
                    .font(.deejMono(12, weight: .bold))
                    .foregroundStyle(isClosest ? Color.deejOrangeHigh : Color.deejOrangeMid)
                    .deejTracking(0.5)
                Text("MI")
                    .font(.deejMono(7, weight: .semibold))
                    .foregroundStyle(.deejOrangeLow)
                    .deejTracking(1.5)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func distanceString(for event: Event) -> String {
        let m = VenueCoordinates.miles(from: userCenter,
                                       to: VenueCoordinates.coordinate(for: event))
        return String(format: "%.1f", m)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM.dd ''yy · EEE"
        return f.string(from: date).uppercased()
    }
}

#Preview {
    DiscoverView()
        .environment(AppServices())
        .preferredColorScheme(.dark)
}
