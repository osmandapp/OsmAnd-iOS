//
//  CoordinateGridFormatting.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 12.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class CoordinateGridFormatting: NSObject {

    private static let swissFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    static func formatSwissGridLV03(lat: Double, lon: Double) -> String {
        let point = SwissGridApproximation.convertWGS84ToLV03(lat: lat, lon: lon)
        return formatSwissPoint(easting: point.easting, northing: point.northing)
    }

    static func formatSwissGridLV95(lat: Double, lon: Double) -> String {
        let point = SwissGridApproximation.convertWGS84ToLV95(lat: lat, lon: lon)
        return formatSwissPoint(easting: point.easting, northing: point.northing)
    }

    static func formatMaidenhead(lat: Double, lon: Double) -> String {
        MaidenheadPoint.toMaidenhead(lat: lat, lon: lon)
    }

    private static func formatSwissPoint(easting: Double, northing: Double) -> String {
        let east = swissFormatter.string(from: NSNumber(value: easting)) ?? "0.00"
        let north = swissFormatter.string(from: NSNumber(value: northing)) ?? "0.00"
        return "\(east), \(north)"
    }
}
