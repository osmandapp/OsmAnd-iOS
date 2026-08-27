//
//  CoordinateFormatHelper.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

enum CoordinateFormatHelper {
    static let exampleLat = 50.43855
    static let exampleLon = 30.50124

    static func resolve(_ ids: [String]) -> [CoordinateFormat] {
        ids.compactMap { BuiltInCoordinateFormat.resolve($0) }
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

    static func exampleString(_ format: CoordinateFormat) -> String {
        guard let legacy = format.legacyFormat else { return "—" }
        let location = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation
        let lat = location?.coordinate.latitude ?? exampleLat
        let lon = location?.coordinate.longitude ?? exampleLon
        return OAOsmAndFormatter.getFormattedCoordinates(withLat: lat, lon: lon, outputFormat: legacy) ?? "—"
    }
}
