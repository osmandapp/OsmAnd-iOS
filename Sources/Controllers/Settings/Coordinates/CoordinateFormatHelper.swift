//
//  CoordinateFormatHelper.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

enum CoordinateFormatHelper {
    private static let exampleLat = 50.43855
    private static let exampleLon = 30.50124
    private static let unavailablePlaceholder = "—"
    
    private static let epsgNumberFormatter: NumberFormatter = {
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

    static func resolve(_ ids: [String]) -> [CoordinateFormat] {
        ids.map { id in
            BuiltInCoordinateFormat.resolve(id) ?? EpsgCatalogRepository.shared.resolveFormat(id)
        }
    }
    
    static func summary(_ format: CoordinateFormat, primary: Bool) -> String {
        if let epsgCode = format.epsgCode {
            return "EPSG:\(epsgCode)"
        }

        let example = exampleString(format)
        if primary {
            return "\(localizedString("coordinate_format_primary")) • \(example)"
        }
        if format.id == CoordinateFormatIds.builtinUtm {
            return "UTM • \(example)"
        }
        if format.id == CoordinateFormatIds.builtinOlc {
            return "OLC • \(example)"
        }
        return example
    }

    static func exampleString(_ coordFormat: CoordinateFormat) -> String {
        let location = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation
        let lat = location?.coordinate.latitude ?? exampleLat
        let lon = location?.coordinate.longitude ?? exampleLon
        return format(coordFormat, lat: lat, lon: lon)
    }

    static func format(_ format: CoordinateFormat, lat: Double, lon: Double) -> String {
        if format.type == .builtIn, let legacy = format.legacyFormat {
            return OAOsmAndFormatter.getFormattedCoordinates(withLat: lat, lon: lon, outputFormat: legacy)
                ?? unavailablePlaceholder
        }
        if let code = format.epsgCode,
           let point = OAEpsgCoordinateTransformer.sharedInstance().fromLonLat(withCode: code, lon: lon, lat: lat) {
            return formatEpsgPoint(easting: point.easting, northing: point.northing)
        }
        return unavailablePlaceholder
    }

    static func formatEpsgPoint(easting: Double, northing: Double) -> String {
        "\(formatEpsgValue(easting)), \(formatEpsgValue(northing))"
    }

    static func formatEpsgValue(_ value: Double) -> String {
        epsgNumberFormatter.string(from: NSNumber(value: value)) ?? unavailablePlaceholder
    }
}
