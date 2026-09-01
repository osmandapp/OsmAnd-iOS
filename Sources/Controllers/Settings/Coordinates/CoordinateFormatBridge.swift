//
//  CoordinateFormatBridge.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 13.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import CoreLocation

@objc enum CoordinateSearchInputMode: Int {
    case latLon = 0
    case utm
    case olc
    case mgrs
    case maidenhead
    case eastingNorthing
}

@objcMembers
final class FormattedCoordinateItem: NSObject {
    let text: String
    let prefix: String?
    
    var copyText: String { text }
    
    init(text: String, prefix: String?) {
        self.text = text
        self.prefix = prefix
        super.init()
    }
}

@objcMembers
final class CoordinateSearchFormatInfo: NSObject {
    let formatId: String
    let title: String
    let inputMode: CoordinateSearchInputMode
    let legacyFormat: Int
    let epsgCode: Int
    
    init(formatId: String,
         title: String,
         inputMode: CoordinateSearchInputMode,
         legacyFormat: Int,
         epsgCode: Int) {
        self.formatId = formatId
        self.title = title
        self.inputMode = inputMode
        self.legacyFormat = legacyFormat
        self.epsgCode = epsgCode
        super.init()
    }
}

@objcMembers
final class CoordinateFormatBridge: NSObject {
    
    static func primaryFormatId(mode: OAApplicationMode) -> String {
        OAAppSettings.sharedManager().coordinateFormatSettingsStorage.getPrimaryId(mode)
    }
    
    static func primaryFormatTitle(mode: OAApplicationMode) -> String {
        let id = primaryFormatId(mode: mode)
        return CoordinateFormatHelper.resolve([id]).first?.title ?? ""
    }
    
    // MARK: - Context menu
    
    static func formatPrimary(lat: Double, lon: Double) -> String {
        CoordinateFormatHelper.formatPrimary(lat: lat, lon: lon)
    }
    
    static func primaryRowPrefix(lat: Double, lon: Double) -> String {
        CoordinateFormatHelper.primaryRowPrefix(lat: lat, lon: lon)
    }

    static func shareLink(lat: Double, lon: Double) -> String {
        CoordinateFormatHelper.shareLink(lat: lat, lon: lon)
    }

    static func osmEditingLink(lat: Double, lon: Double) -> String? {
        CoordinateFormatHelper.osmEditingLink(lat: lat, lon: lon)
    }

    static func collapsedRows(lat: Double, lon: Double) -> [FormattedCoordinateItem] {
        CoordinateFormatHelper.collapsedLocationData(lat: lat, lon: lon).map { row in
            FormattedCoordinateItem(text: row.text, prefix: row.displayPrefix)
        }
    }
    
    // MARK: - Search format
    
    static func primaryFormatId() -> String {
        OAAppSettings.sharedManager().coordinateFormatSettingsStorage.getPrimaryId(
            OAAppSettings.sharedManager().applicationMode.get()
        )
    }
    
    static func formatId(fromLegacyFormat legacy: Int) -> String {
        CoordinateFormatIds.fromOldFormat(legacy) ?? CoordinateFormatIds.builtinDdd
    }
    
    static func resolveSearchFormat(_ formatId: String?) -> CoordinateSearchFormatInfo {
        let normalized = CoordinateFormatIds.normalize(formatId) ?? CoordinateFormatIds.builtinDdd
        let format = CoordinateFormatHelper.resolve([normalized]).first
        ?? BuiltInCoordinateFormat.ddd.toCoordinateFormat()
        let legacy = format.legacyFormat ?? -1
        let epsg = format.epsgCode ?? 0
        let mode: CoordinateSearchInputMode
        switch normalized {
        case CoordinateFormatIds.builtinUtm:
            mode = .utm
        case CoordinateFormatIds.builtinOlc:
            mode = .olc
        case CoordinateFormatIds.builtinMgrs:
            mode = .mgrs
        case CoordinateFormatIds.builtinMaidenhead:
            mode = .maidenhead
        case CoordinateFormatIds.builtinSwissGrid,
            CoordinateFormatIds.builtinSwissGridPlus:
            mode = .eastingNorthing
        default:
            mode = epsg > 0 ? .eastingNorthing : .latLon
        }
        return CoordinateSearchFormatInfo(
            formatId: normalized,
            title: format.title,
            inputMode: mode,
            legacyFormat: legacy,
            epsgCode: epsg
        )
    }
    /// Prefill field strings for the given format. Never returns nil values.
    static func prefillFields(lat: Double, lon: Double, formatId: String?) -> [String: String] {
        let info = resolveSearchFormat(formatId)
        var result: [String: String] = [
            "lat": "",
            "lon": "",
            "zone": "",
            "easting": "",
            "northing": "",
            "olc": "",
            "mgrs": "",
            "maidenhead": ""
        ]
        switch info.inputMode {
        case .latLon:
            let legacy = info.legacyFormat
            if legacy == Int(FORMAT_DEGREES) || legacy == Int(FORMAT_MINUTES) || legacy == Int(FORMAT_SECONDS) {
                result["lat"] = OALocationConvert.convert(OAMapUtils.checkLatitude(lat), outputType: legacy) ?? ""
                result["lon"] = OALocationConvert.convert(OAMapUtils.checkLongitude(lon), outputType: legacy) ?? ""
            } else {
                result["lat"] = OALocationConvert.convert(OAMapUtils.checkLatitude(lat), outputType: Int(FORMAT_DEGREES)) ?? ""
                result["lon"] = OALocationConvert.convert(OAMapUtils.checkLongitude(lon), outputType: Int(FORMAT_DEGREES)) ?? ""
            }
        case .utm:
            // leave empty here — VC already fills via GeographicLib; optional later
            break
        case .olc:
            result["olc"] = OALocationConvert.getLocationOlcName(lat, lon: lon) ?? ""
        case .mgrs:
            result["mgrs"] = OALocationConvert.getMgrsCoordinateString(lat, lon: lon) ?? ""
        case .maidenhead:
            result["maidenhead"] = MaidenheadPoint.toMaidenhead(lat: lat, lon: lon)
        case .eastingNorthing:
            if info.formatId == CoordinateFormatIds.builtinSwissGrid {
                let p = SwissGridApproximation.convertWGS84ToLV03(lat: lat, lon: lon)
                result["easting"] = CoordinateFormatHelper.formatEpsgValue(p.easting)
                result["northing"] = CoordinateFormatHelper.formatEpsgValue(p.northing)
            } else if info.formatId == CoordinateFormatIds.builtinSwissGridPlus {
                let p = SwissGridApproximation.convertWGS84ToLV95(lat: lat, lon: lon)
                result["easting"] = CoordinateFormatHelper.formatEpsgValue(p.easting)
                result["northing"] = CoordinateFormatHelper.formatEpsgValue(p.northing)
            } else if info.epsgCode > 0,
                      let point = OAEpsgCoordinateTransformer.sharedInstance()
                .fromLonLat(withCode: info.epsgCode, lon: lon, lat: lat) {
                result["easting"] = CoordinateFormatHelper.formatEpsgValue(point.easting)
                result["northing"] = CoordinateFormatHelper.formatEpsgValue(point.northing)
            }
        @unknown default:
            break
        }
        return result
    }
    
    static func parseLocation(formatId: String?,
                              lat: String?,
                              lon: String?,
                              easting: String?,
                              northing: String?,
                              zone: String?,
                              olc: String?,
                              mgrs: String?,
                              maidenhead: String?) -> CLLocation? {
        let info = resolveSearchFormat(formatId)
        switch info.inputMode {
        case .latLon:
            let latV = OALocationConvert.convert(lat ?? "")
            let lonV = OALocationConvert.convert(lon ?? "")
            guard !latV.isNaN, !lonV.isNaN else { return nil }
            return CLLocation(latitude: latV, longitude: lonV)
        case .maidenhead:
            guard let parsed = MaidenheadPoint.parse(maidenhead) else { return nil }
            return CLLocation(latitude: parsed.lat, longitude: parsed.lon)
        case .eastingNorthing:
            let e = parseMetric(easting)
            let n = parseMetric(northing)
            guard !e.isNaN, !n.isNaN else { return nil }
            if info.formatId == CoordinateFormatIds.builtinSwissGrid {
                let p = SwissGridApproximation.convertLV03ToWGS84(easting: e, northing: n)
                return CLLocation(latitude: p.lat, longitude: p.lon)
            }
            if info.formatId == CoordinateFormatIds.builtinSwissGridPlus {
                let p = SwissGridApproximation.convertLV95ToWGS84(easting: e, northing: n)
                return CLLocation(latitude: p.lat, longitude: p.lon)
            }
            if info.epsgCode > 0 {
                return OAEpsgCoordinateTransformer.sharedInstance()
                    .toLonLat(withCode: info.epsgCode, easting: e, northing: n)
            }
            return nil
        default:
            return nil
        }
    }
    
    private static func parseMetric(_ raw: String?) -> Double {
        guard var s = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
            return .nan
        }
        s = s.replacingOccurrences(of: " ", with: "")
        s = s.replacingOccurrences(of: ",", with: ".")
        return Double(s) ?? .nan
    }
}
