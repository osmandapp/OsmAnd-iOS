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

private enum LegacyGridFormatName: String {
    case dms = "DD_MM_SS"
    case dm = "DD_MM_MMM"
    case digital = "DD_DDDDD"
    case utm = "UTM"
    case mgrs = "MGRS"
    case olc = "OLC"

    var formatId: String {
        switch self {
        case .dms: return CoordinateFormatIds.builtinDms
        case .dm: return CoordinateFormatIds.builtinDdm
        case .digital: return CoordinateFormatIds.builtinDdd
        case .utm: return CoordinateFormatIds.builtinUtm
        case .mgrs: return CoordinateFormatIds.builtinMgrs
        case .olc: return CoordinateFormatIds.builtinOlc
        }
    }
}

private enum LegacyStoredGridFormat: Int {
    case dms = 0
    case dm = 1
    case digital = 2
    case utm = 3
    case mgrs = 4

    var formatId: String {
        switch self {
        case .dms: return CoordinateFormatIds.builtinDms
        case .dm: return CoordinateFormatIds.builtinDdm
        case .digital: return CoordinateFormatIds.builtinDdd
        case .utm: return CoordinateFormatIds.builtinUtm
        case .mgrs: return CoordinateFormatIds.builtinMgrs
        }
    }
}

@objcMembers
final class GridFormatWrapper: NSObject {
    static var defaultFormatId: String {
        CoordinateFormatIds.builtinDdd
    }

    static func migratePreferenceValue(_ value: Any?) -> String {
        if let stringValue = value as? String {
            if let normalized = CoordinateFormatIds.normalize(stringValue) {
                return normalized
            }
            if let legacyName = LegacyGridFormatName(rawValue: stringValue) {
                return legacyName.formatId
            }
        }
        if let numberValue = value as? NSNumber,
           let legacyStored = LegacyStoredGridFormat(rawValue: numberValue.intValue) {
            return legacyStored.formatId
        }
        return defaultFormatId
    }
}
