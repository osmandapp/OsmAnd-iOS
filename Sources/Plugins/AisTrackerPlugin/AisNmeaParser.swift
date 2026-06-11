//
//  AisNmeaParser.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CoreLocation

struct AisNmeaParser {
    static func parseLocation(from sentence: String) -> CLLocation? {
        let line = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard line.hasPrefix("$"), isChecksumValid(line) else { return nil }

        let payload = line.dropFirst().split(separator: "*", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
        let fields = payload.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        guard let type = fields.first else { return nil }

        if type.hasSuffix("RMC") {
            return parseRMC(fields)
        } else if type.hasSuffix("GGA") {
            return parseGGA(fields)
        }
        return nil
    }

    private static func parseRMC(_ fields: [String]) -> CLLocation? {
        guard fields.count > 9, fields[2] == "A",
              let latitude = coordinate(fields[3], hemisphere: fields[4]),
              let longitude = coordinate(fields[5], hemisphere: fields[6]) else {
            return nil
        }

        let speed = (Double(fields[7]) ?? -1) * 0.514444
        let course = Double(fields[8]) ?? -1
        let timestamp = date(time: fields[1], date: fields[9]) ?? Date()
        return CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                          altitude: 0,
                          horizontalAccuracy: 10,
                          verticalAccuracy: -1,
                          course: course,
                          speed: speed,
                          timestamp: timestamp)
    }

    private static func parseGGA(_ fields: [String]) -> CLLocation? {
        guard fields.count > 9, (Int(fields[6]) ?? 0) > 0,
              let latitude = coordinate(fields[2], hemisphere: fields[3]),
              let longitude = coordinate(fields[4], hemisphere: fields[5]) else {
            return nil
        }

        let altitude = Double(fields[9]) ?? 0
        let hdop = Double(fields[8]) ?? 1
        return CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                          altitude: altitude,
                          horizontalAccuracy: max(5, hdop * 5),
                          verticalAccuracy: 10,
                          course: -1,
                          speed: -1,
                          timestamp: Date())
    }

    private static func coordinate(_ value: String, hemisphere: String) -> CLLocationDegrees? {
        guard let raw = Double(value), value.count >= 4 else { return nil }
        let degrees = floor(raw / 100)
        let minutes = raw - degrees * 100
        var result = degrees + minutes / 60
        if hemisphere == "S" || hemisphere == "W" {
            result = -result
        }
        return result
    }

    private static func date(time: String, date: String) -> Date? {
        guard time.count >= 6, date.count == 6 else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "ddMMyyHHmmss.SS"
        let normalizedTime = time.contains(".") ? time : "\(time).00"
        return formatter.date(from: "\(date)\(normalizedTime)")
    }

    private static func isChecksumValid(_ line: String) -> Bool {
        let parts = line.split(separator: "*", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, let expected = UInt8(parts[1].prefix(2), radix: 16) else {
            return true
        }

        let payload = parts[0].dropFirst().utf8.reduce(UInt8(0)) { $0 ^ $1 }
        return payload == expected
    }
}
