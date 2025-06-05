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
    
    func projection() -> OAProjection {
        switch self {
        case .dms, .dm, .digital:
            return .wgs84
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
        case .digital:
            return .decimal
        case .utm, .mgrs:
            return .decimal
        }
    }
    
    static func valueOf(_ formatId: Int32) -> GridFormat {
        switch formatId {
        case 0:
            return .digital
        case 1:
            return .dm
        case 2:
            return .dms
        case 3:
            return .utm
        case 4:
            return .dms
        case 5:
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

@objc
enum OAProjection: Int32 {
    case wgs84 = 0
    case utm
    case mgrs
    case mercator
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
        let format = GridFormat.valueOf(geoFormatId)
        return NSNumber(value: format.rawValue)
    }
    
    static func projection(for format: GridFormat) -> OAProjection {
        format.projection()
    }
    
    static func getFormat(for format: GridFormat) -> OAFormat {
        format.getFormat()
    }
    
    static func needSuffixesForFormat(_ format: GridFormat) -> Bool {
        format != .utm && format != .mgrs
    }
}
