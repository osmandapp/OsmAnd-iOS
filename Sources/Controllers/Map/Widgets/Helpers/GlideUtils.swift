//
//  GlideUtils.swift
//  OsmAnd Maps
//
//  Created by Skalii on 05.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAGlideUtils)
@objcMembers
final class GlideUtils: NSObject {

    private static let glideRatioFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    static let maxValueToDisplay: Double = 150.0
    static let maxValueToFormat: Double = 100.0
    static let minAcceptableValue: Double = 0.1

    static func calculateFormattedRatio(_ l1: CLLocationCoordinate2D, l2: CLLocationCoordinate2D, a1: Double, a2: Double) -> String {
        let distance = OAMapUtils.getDistance(l1.latitude, lon1: l1.longitude, lat2: l2.latitude, lon2: l2.longitude)
        return calculateFormattedRatio(distance, altDif: a2 - a1)
    }

    static func calculateFormattedRatio(_ distance: Double, altDif: Double) -> String {
        let sign = altDif < 0 ? -1 : 1

        // Round arguments to '0' if they are smaller
        // in absolute value than the minimum acceptable value
        let newDistance = abs(distance) < minAcceptableValue ? 0 : distance
        let newAltDif = abs(altDif) < minAcceptableValue ? 0 : altDif

        // Calculate and round glide ratio if needed
        var absRatio = 0.0
        if newDistance > 0 {
            absRatio = newAltDif != 0 ? abs(newDistance / newAltDif) : 1
        }
        if absRatio < minAcceptableValue {
            absRatio = 0
        }

        let divider = newAltDif != 0 ? 1 : 0

        if absRatio > maxValueToDisplay || (absRatio == 1 && divider == 0) {
            return String(format: localizedString("ltr_or_rtl_combine_via_colon_with_space"), "1", "0")
        } else if absRatio > maxValueToFormat {
            let formattedRatio = String(format: "%.0f", absRatio * Double(sign))
            return String(format: localizedString("ltr_or_rtl_combine_via_colon_with_space"), formattedRatio, "\(divider)")
        } else {
            let formattedRatio = glideRatioFormatter.string(from: NSNumber(value: absRatio * Double(sign))) ?? "0"
            return String(format: localizedString("ltr_or_rtl_combine_via_colon_with_space"), formattedRatio, "\(divider)")
        }
    }

    static func areAltitudesEqual(_ a1: Double?, _ a2: Double?) -> Bool {
        guard let a1 else {
            return a2 == nil
        }
        guard let a2 else {
            return false
        }
        return abs(a1 - a2) > 0.01
    }
}
