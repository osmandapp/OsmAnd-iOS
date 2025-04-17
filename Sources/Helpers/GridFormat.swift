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
    
    var id: Int32 {
        switch self {
        case .dms:
            return 0
        case .dm:
            return 1
        case .digital:
            return 2
        case .utm:
            return 3
        case .mgrs:
            return 4
        }
    }
    
    var title: String {
        switch self {
        case .dms:
            return localizedString("navigate_point_format_DMS")
        case .dm:
            return localizedString("navigate_point_format_DM")
        case .digital:
            return localizedString("navigate_point_format_D")
        case .utm:
            return localizedString("navigate_point_format_UTM")
        case .mgrs:
            return localizedString("navigate_point_mgrs")
        }
    }
    
    static func valueOf(_ formatId: Int32) -> GridFormat {
        return Self.allCases.first(where: { $0.id == formatId }) ?? .dms
    }
}

@objcMembers
final class GridFormatWrapper: NSObject {
    @objc static func gridFormatRaw(forGeoFormat geoFormatId: Int32) -> NSNumber {
        let format = GridFormat.valueOf(geoFormatId)
        return NSNumber(value: format.rawValue)
    }
}
