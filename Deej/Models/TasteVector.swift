//
//  TasteVector.swift
//  Per-user average rating across all logged events, by dimension.
//  Used by the recommendation algorithm — see PLAN.md §4.4.
//

import Foundation

struct TasteVector: Codable, Sendable, Hashable {
    var averages: [Dimension: Double]
    var sampleSize: Int
    var computedAt: Date

    enum CodingKeys: String, CodingKey {
        case averages
        case sampleSize  = "sample_size"
        case computedAt  = "computed_at"
    }

    /// Incremental update on each new log — O(7), no full recomputation.
    func adding(_ log: EventLog) -> TasteVector {
        let newSize = sampleSize + 1
        var next: [Dimension: Double] = [:]
        for d in Dimension.allCases {
            let prev = averages[d] ?? 0
            let new  = Double(log.dimensionRatings[d] ?? 0)
            next[d] = (prev * Double(sampleSize) + new) / Double(newSize)
        }
        return TasteVector(averages: next, sampleSize: newSize, computedAt: .now)
    }

    static let empty = TasteVector(averages: [:], sampleSize: 0, computedAt: .distantPast)

    /// Cosine similarity in 7-dim space, used as the `tasteMatch` recommendation signal.
    func cosineSimilarity(to other: TasteVector) -> Double {
        let dims = Dimension.allCases
        var dot = 0.0, magA = 0.0, magB = 0.0
        for d in dims {
            let a = averages[d] ?? 0
            let b = other.averages[d] ?? 0
            dot  += a * b
            magA += a * a
            magB += b * b
        }
        let denom = (magA.squareRoot() * magB.squareRoot())
        return denom > 0 ? dot / denom : 0
    }
}
