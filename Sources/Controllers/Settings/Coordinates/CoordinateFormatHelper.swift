//
//  CoordinateFormatHelper.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

enum CoordinateFormatHelper {
    private enum LocationShareLinkFormat {
        static let share = "https://osmand.net/map?pin=%.6f,%.6f#%d/%.4f/%.4f"
        static let osm = "https://www.openstreetmap.org/?mlat=%.4f&mlon=%.4f#map=%i/%.4f/%.4f"
    }

    private static let exampleLat = 50.43855
    private static let exampleLon = 30.50124
    private static let unavailablePlaceholder = "—"
    
    private static let searchDebounce: TimeInterval = 0.25
    private static var searchWorkItem: DispatchWorkItem?
    
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
        var parts: [String] = []
        if primary {
            parts.append(localizedString("coordinate_format_primary"))
        }
        if let epsgCode = format.epsgCode {
            parts.append("EPSG:\(epsgCode)")
        } else {
            if format.id == CoordinateFormatIds.builtinUtm {
                parts.append("UTM")
            } else if format.id == CoordinateFormatIds.builtinOlc {
                parts.append("OLC")
            }
            parts.append(exampleString(format))
        }
        return parts.joined(separator: " • ")
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
    
    static func preferredFormats() -> [CoordinateFormat] {
        let storage = OAAppSettings.sharedManager().coordinateFormatSettingsStorage
        return resolve(storage.preferredIds())
    }

    static func formatPreferred(lat: Double, lon: Double) -> [FormattedCoordinate] {
        preferredFormats().map { format in
            FormattedCoordinate(
                format: format,
                text: Self.format(format, lat: lat, lon: lon)
            )
        }
    }

    static func formatPrimary(lat: Double, lon: Double) -> String {
        if let primary = formatPreferred(lat: lat, lon: lon).first {
            return primary.text
        }
        return OAOsmAndFormatter.getFormattedCoordinates(
            withLat: lat, lon: lon, outputFormat: Int(FORMAT_DEGREES)
        ) ?? unavailablePlaceholder
    }

    static func primaryRowPrefix(lat: Double, lon: Double) -> String {
        if let code = preferredFormats().first?.epsgCode {
            return "EPSG:\(code)"
        }
        return localizedString("coordinates")
    }

    static func shareLink(lat: Double, lon: Double) -> String {
        let zoom = Int(OARootViewController.instance().mapPanel.mapViewController.getMapZoom())
        return String(format: LocationShareLinkFormat.share, lat, lon, zoom, lat, lon)
    }

    static func osmEditingLink(lat: Double, lon: Double) -> String? {
        guard OAPluginsHelper.isEnabled(OAOsmEditingPlugin.self) else { return nil }
        let zoom = Int(OARootViewController.instance().mapPanel.mapViewController.getMapZoom())
        return String(format: LocationShareLinkFormat.osm, lat, lon, zoom, lat, lon)
    }

    static func collapsedLocationData(lat: Double, lon: Double) -> [FormattedCoordinate] {
        var rows = [FormattedCoordinate]()
        let preferred = formatPreferred(lat: lat, lon: lon)

        if let short = OAOsmAndFormatter.getFormattedCoordinates(
            withLat: lat, lon: lon, outputFormat: Int(FORMAT_DEGREES_SHORT)
        ), !short.isEmpty {
            rows.append(.plain(short))
        }
        if preferred.count > 1 {
            rows.append(contentsOf: preferred.dropFirst())
        }

        rows.append(.plain(shareLink(lat: lat, lon: lon)))

        if let osm = osmEditingLink(lat: lat, lon: lon) {
            rows.append(.plain(osm))
        }
        return rows
    }
}
