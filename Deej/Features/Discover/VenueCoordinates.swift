//
//  VenueCoordinates.swift
//  Static venue → (lat, lon) lookup. Phase 6 stand-in until we add
//  latitude/longitude columns to public.events. Production will join in
//  real coords (geocoded at event creation time or supplied by the user).
//

import CoreLocation
import Foundation

enum VenueCoordinates {
    /// Known NYC nightlife venues. Coordinates are approximate.
    private static let table: [String: CLLocationCoordinate2D] = [
        "BROOKLYN_STEEL":   .init(latitude: 40.7180, longitude: -73.9425),
        "THE_SULTAN_ROOM":  .init(latitude: 40.7032, longitude: -73.9237),
        "PUBLIC_RECORDS":   .init(latitude: 40.6770, longitude: -73.9866),
        "KNOCKDOWN_CENTER": .init(latitude: 40.7095, longitude: -73.9215),
        "ELSEWHERE":        .init(latitude: 40.7068, longitude: -73.9237),
        "HOUSE_OF_YES":     .init(latitude: 40.7064, longitude: -73.9333),
        "MSG":              .init(latitude: 40.7505, longitude: -73.9934),
        "BARCLAYS":         .init(latitude: 40.6826, longitude: -73.9754),
        "BOWERY_BALLROOM":  .init(latitude: 40.7204, longitude: -73.9929),
        "NOWADAYS":         .init(latitude: 40.7050, longitude: -73.9202)
    ]

    /// Default fallback for unknown venues: Williamsburg-ish.
    static let defaultCenter = CLLocationCoordinate2D(latitude: 40.7128, longitude: -73.9500)

    /// Look up coords for an Event, falling back to defaultCenter with a
    /// deterministic offset so unknown venues still spread out on the map.
    static func coordinate(for event: Event) -> CLLocationCoordinate2D {
        if let known = table[event.venueName] { return known }
        // Deterministic small jitter so two unknowns don't collide.
        let h = abs(event.venueName.hashValue)
        let dLat = Double((h % 200) - 100) / 4000.0          // ±0.025°
        let dLon = Double(((h / 200) % 200) - 100) / 4000.0
        return CLLocationCoordinate2D(
            latitude: defaultCenter.latitude + dLat,
            longitude: defaultCenter.longitude + dLon
        )
    }

    /// Rough straight-line distance in miles between two coords.
    static func miles(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let la = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let lb = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return la.distance(from: lb) / 1609.34
    }
}
