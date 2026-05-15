//
//  SupabaseClient.swift
//  Single shared Supabase client.
//
//  Configured with a flexible date decoder/encoder that handles both
//  Postgres `timestamptz` (ISO8601 with fractional seconds + TZ) and `date`
//  (YYYY-MM-DD, used for `events.event_date`).
//

import Foundation
import Supabase

enum DeejSupabase {
    static let shared: SupabaseClient = {
        SupabaseClient(
            supabaseURL: Secrets.supabaseURL,
            supabaseKey: Secrets.supabaseAnonKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    encoder: configuredEncoder(),
                    decoder: configuredDecoder()
                )
            )
        )
    }()

    // MARK: encoders/decoders
    private static func configuredEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func configuredDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            if let date = isoWithFractionalSeconds.date(from: raw) { return date }
            if let date = isoPlain.date(from: raw)                  { return date }
            if let date = dateOnly.date(from: raw)                  { return date }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognized date format: \(raw)"
            )
        }
        return decoder
    }

    // MARK: cached formatters
    // ISO8601DateFormatter + DateFormatter are documented as thread-safe by
    // Apple; the compiler doesn't know that, so we mark them nonisolated(unsafe).
    nonisolated(unsafe) private static let isoWithFractionalSeconds: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    nonisolated(unsafe) private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    nonisolated(unsafe) private static let dateOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
