//
//  MaidenheadPoint.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 12.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

enum MaidenheadPoint {

    static func toMaidenhead(lat: Double, lon: Double) -> String {
        var lon = lon + 180.0
        var lat = lat + 90.0
        lon = min(max(lon, 0), 360.0 - 1e-4)
        lat = min(max(lat, 0), 180.0 - 1e-4)

        var sb = ""

        let lonField = Int(lon / 20 + 1e-6)
        let latField = Int(lat / 10 + 1e-6)
        lon -= Double(lonField) * 20
        lat -= Double(latField) * 10
        sb.append(charOffset(base: "A", offset: lonField))
        sb.append(charOffset(base: "A", offset: latField))

        let lonSquare = Int(lon / 2 + 1e-6)
        let latSquare = Int(lat / 1 + 1e-6)
        lon -= Double(lonSquare) * 2
        lat -= Double(latSquare) * 1
        sb.append(charOffset(base: "0", offset: lonSquare))
        sb.append(charOffset(base: "0", offset: latSquare))

        let lonSub = Int(lon * 12 + 1e-6)
        let latSub = Int(lat * 24 + 1e-6)
        lon -= Double(lonSub) / 12.0
        lat -= Double(latSub) / 24.0
        sb.append(charOffset(base: "A", offset: lonSub))
        sb.append(charOffset(base: "A", offset: latSub))
        sb.append(" ")

        let lonExtSquare = Int(lon * 120 + 1e-6)
        let latExtSquare = Int(lat * 240 + 1e-6)
        lon -= Double(lonExtSquare) / 120.0
        lat -= Double(latExtSquare) / 240.0
        sb.append(charOffset(base: "0", offset: lonExtSquare))
        sb.append(charOffset(base: "0", offset: latExtSquare))

        let lonExtSub = Int(lon * 2880 + 1e-6)
        let latExtSub = Int(lat * 5760 + 1e-6)
        sb.append(charOffset(base: "A", offset: lonExtSub))
        sb.append(charOffset(base: "A", offset: latExtSub))

        return sb
    }

    static func parse(_ maidenhead: String?) -> (lat: Double, lon: Double)? {
        guard var text = maidenhead?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return nil }

        text = text.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: .regularExpression)
            .uppercased()

        let pattern = #"^[A-R]{2}([0-9]{2}([A-X]{2}([0-9]{2}([A-X]{2})?)?)?)?$"#
        guard text.range(of: pattern, options: .regularExpression) != nil else { return nil }

        var lon = -180.0
        var lat = -90.0

        if text.count >= 2 {
            lon += Double(text[text.index(text.startIndex, offsetBy: 0)].asciiValue! - Character("A").asciiValue!) * 20.0
            lat += Double(text[text.index(text.startIndex, offsetBy: 1)].asciiValue! - Character("A").asciiValue!) * 10.0
        }
        if text.count >= 4 {
            lon += Double(text[text.index(text.startIndex, offsetBy: 2)].asciiValue! - Character("0").asciiValue!) * 2.0
            lat += Double(text[text.index(text.startIndex, offsetBy: 3)].asciiValue! - Character("0").asciiValue!) * 1.0
        } else {
            return (lat + 5.0, lon + 10.0)
        }
        if text.count >= 6 {
            lon += Double(text[text.index(text.startIndex, offsetBy: 4)].asciiValue! - Character("A").asciiValue!) * (5.0 / 60.0)
            lat += Double(text[text.index(text.startIndex, offsetBy: 5)].asciiValue! - Character("A").asciiValue!) * (2.5 / 60.0)
        } else {
            return (lat + 0.5, lon + 1.0)
        }
        if text.count >= 8 {
            lon += Double(text[text.index(text.startIndex, offsetBy: 6)].asciiValue! - Character("0").asciiValue!) * (5.0 / 600.0)
            lat += Double(text[text.index(text.startIndex, offsetBy: 7)].asciiValue! - Character("0").asciiValue!) * (2.5 / 600.0)
        } else {
            return (lat + 1.25 / 60.0, lon + 2.5 / 60.0)
        }
        if text.count >= 10 {
            lon += Double(text[text.index(text.startIndex, offsetBy: 8)].asciiValue! - Character("A").asciiValue!) * (5.0 / 14400.0)
            lat += Double(text[text.index(text.startIndex, offsetBy: 9)].asciiValue! - Character("A").asciiValue!) * (2.5 / 14400.0)
            lon += 2.5 / 14400.0
            lat += 1.25 / 14400.0
        } else {
            return (lat + 1.25 / 600.0, lon + 2.5 / 600.0)
        }
        return (lat, lon)
    }

    private static func charOffset(base: Character, offset: Int) -> String {
        guard let baseValue = base.asciiValue else { return "" }
        return String(UnicodeScalar(baseValue + UInt8(offset)))
    }
}
