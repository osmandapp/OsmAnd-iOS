//
//  GridFormat.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 16.04.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objc
enum GridFormat: Int32, CaseIterable {
    case dms
    case dm
    case digital
    case utm
    case olc
    case mgrs
    case swissGrid
    case swissGridPlus
    case maidenhead
    
    var id: Int32 { rawValue }
    
    var title: String {
        switch self {
        case .dms:
            return localizedString("dd_mm_ss_format")
        case .dm:
            return localizedString("dd_mm_mmm_format")
        case .digital:
            return localizedString("dd_ddddd_format")
        case .utm:
            return localizedString("navigate_point_format_UTM")
        case .olc:
            return localizedString("navigate_point_olc")
        case .mgrs:
            return localizedString("navigate_point_mgrs")
        case .swissGrid:
            return localizedString("navigate_point_format_swiss_grid")
        case .swissGridPlus:
            return localizedString("navigate_point_format_swiss_grid_plus")
        case .maidenhead:
            return localizedString("navigate_point_format_maidenhead")
        }
    }
    
    func projection() -> OAProjection {
        switch self {
        case .dms, .dm, .digital:
            return .wgs84
        case .olc:
            return .olc
        case .maidenhead:
            return .mls
        case .swissGrid, .swissGridPlus:
            return .homv2
        case .utm:
            return .utm
        case .mgrs:
            return .mgrs
        }
    }
    
    func getFormat() -> OAFormat {
        switch self {
        case .dms:
            return .dms
        case .dm:
            return .dm
        case .digital, .utm, .olc, .mgrs, .swissGrid, .swissGridPlus, .maidenhead:
            return .decimal
        }
    }
    
    var needSuffixes: Bool {
        switch self {
        case .utm, .olc, .mgrs, .swissGrid, .swissGridPlus, .maidenhead:
            return false
        default:
            return true
        }
    }
    
    var epsgCode: NSNumber? {
        switch self {
        case .swissGrid:
            return 21781
        case .swissGridPlus:
            return 2056
        default:
            return nil
        }
    }
    
    var formatId: String {
        switch self {
        case .dms:
            return CoordinateFormatIds.builtinDms
        case .dm:
            return CoordinateFormatIds.builtinDdm
        case .digital:
            return CoordinateFormatIds.builtinDdd
        case .utm:
            return CoordinateFormatIds.builtinUtm
        case .olc:
            return CoordinateFormatIds.builtinOlc
        case .mgrs:
            return CoordinateFormatIds.builtinMgrs
        case .swissGrid:
            return CoordinateFormatIds.builtinSwissGrid
        case .swissGridPlus:
            return CoordinateFormatIds.builtinSwissGridPlus
        case .maidenhead:
            return CoordinateFormatIds.builtinMaidenhead
        }
    }
    static func from(formatId: String?) -> GridFormat? {
        switch CoordinateFormatIds.normalize(formatId) {
        case CoordinateFormatIds.builtinDms:
            return .dms
        case CoordinateFormatIds.builtinDdm:
            return .dm
        case CoordinateFormatIds.builtinDdd:
            return .digital
        case CoordinateFormatIds.builtinUtm:
            return .utm
        case CoordinateFormatIds.builtinOlc:
            return .olc
        case CoordinateFormatIds.builtinMgrs:
            return .mgrs
        case CoordinateFormatIds.builtinSwissGrid:
            return .swissGrid
        case CoordinateFormatIds.builtinSwissGridPlus:
            return .swissGridPlus
        case CoordinateFormatIds.builtinMaidenhead:
            return .maidenhead
        default:
            return nil
        }
    }
    
    static func valueOf(_ formatId: Int) -> GridFormat {
        if let id = CoordinateFormatIds.fromOldFormat(formatId),
           let format = from(formatId: id) {
            return format
        }
        return .digital
    }
}

@objc
enum GridLabelsPosition: Int32, CaseIterable {
    case edges
    case center
    
    private var iconName: String {
        switch self {
        case .edges:
            return "ic_custom_grid_label_edges"
        case .center:
            return "ic_custom_grid_label_center"
        }
    }
    
    private var titleKey: String {
        switch self {
        case .edges:
            return "shared_string_edges"
        case .center:
            return "position_on_map_center"
        }
    }
    
    var icon: UIImage? {
        UIImage(named: iconName)
    }
    
    var title: String {
        localizedString(titleKey)
    }
}

@objc
enum OAProjection: Int32 {
    case wgs84 = 0
    case olc = 1
    case mls = 2
    case homv2 = 3
    case ostereo = 4
    case tm = 5
    case utm = 6
    case mgrs = 7
    case mercator = 8
}

@objc
enum OAFormat: Int32 {
    case decimal = 0
    case dms
    case dm
}

@objcMembers
final class GridFormatWrapper: NSObject {
    static func gridFormatRaw(forGeoFormat geoFormatId: Int32) -> NSNumber {
        let format = GridFormat.valueOf(Int(geoFormatId))
        return NSNumber(value: format.rawValue)
    }
    
    static func gridFormatRaw(forFormatId formatId: String?) -> NSNumber {
        NSNumber(value: gridFormat(forFormatId: formatId).rawValue)
    }
    
    static func formatId(forGeoFormat geoFormatId: Int32) -> String {
        GridFormat.valueOf(Int(geoFormatId)).formatId
    }
    
    static func formatId(forRaw raw: Int32) -> String {
        GridFormat(rawValue: raw)?.formatId ?? CoordinateFormatIds.builtinDdd
    }
    
    static func projection(for format: GridFormat) -> OAProjection {
        format.projection()
    }
    
    static func getFormat(for format: GridFormat) -> OAFormat {
        format.getFormat()
    }
    
    static func needSuffixesForFormat(_ format: GridFormat) -> Bool {
        format.needSuffixes
    }
    
    static func gridFormat(forFormatId formatId: String?) -> GridFormat {
        GridFormat.from(formatId: formatId) ?? .digital
    }
    
    static func migratePreferenceValue(_ value: Any?) -> String {
        if let stringValue = value as? String {
            if let normalized = CoordinateFormatIds.normalize(stringValue) {
                return normalized
            }
            
            switch stringValue {
            case "DD_MM_SS":
                return CoordinateFormatIds.builtinDms
            case "DD_MM_MMM":
                return CoordinateFormatIds.builtinDdm
            case "DD_DDDDD":
                return CoordinateFormatIds.builtinDdd
            case "UTM":
                return CoordinateFormatIds.builtinUtm
            case "MGRS":
                return CoordinateFormatIds.builtinMgrs
            case "OLC":
                return CoordinateFormatIds.builtinOlc
            default:
                break
            }
        }
        if let numberValue = value as? NSNumber {
            let raw = numberValue.intValue
            
            if let fromGeo = CoordinateFormatIds.fromOldFormat(raw) {
                return fromGeo
            }
            if let format = GridFormat(rawValue: Int32(raw)) {
                return format.formatId
            }
        }
        return CoordinateFormatIds.builtinDdd
    }
}
