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
    case mgrs
    
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
        case .mgrs:
            return localizedString("navigate_point_mgrs")
        }
    }
    
    static func valueOf(_ formatId: Int) -> GridFormat {
        switch formatId {
        case MAP_GEO_FORMAT_DEGREES:
            return .digital
        case MAP_GEO_FORMAT_MINUTES:
            return .dm
        case MAP_GEO_FORMAT_SECONDS:
            return .dms
        case MAP_GEO_UTM_FORMAT:
            return .utm
        case MAP_GEO_OLC_FORMAT:
            return .dms
        case MAP_GEO_MGRS_FORMAT:
            return .mgrs
        default:
            return .dms
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

@objcMembers
final class GridFormatWrapper: NSObject {
    static func gridFormatRaw(forGeoFormat geoFormatId: Int32) -> NSNumber {
        let format = GridFormat.valueOf(Int(geoFormatId))
        return NSNumber(value: format.rawValue)
    }
    
    static func needSuffixesForFormat(_ format: GridFormat) -> Bool {
        format != .utm && format != .mgrs
    }
}
