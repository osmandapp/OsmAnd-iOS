//
//  BuiltInCoordinateFormat.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 07.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

enum BuiltInCoordinateFormat: CaseIterable {
    case ddd
    case ddm
    case dms
    case utm
    case olc
    case mgrs
    case swissGrid
    case swissGridPlus
    case maidenhead

    var id: String {
        switch self {
        case .ddd: return CoordinateFormatIds.builtinDdd
        case .ddm: return CoordinateFormatIds.builtinDdm
        case .dms: return CoordinateFormatIds.builtinDms
        case .utm: return CoordinateFormatIds.builtinUtm
        case .olc: return CoordinateFormatIds.builtinOlc
        case .mgrs: return CoordinateFormatIds.builtinMgrs
        case .swissGrid: return CoordinateFormatIds.builtinSwissGrid
        case .swissGridPlus: return CoordinateFormatIds.builtinSwissGridPlus
        case .maidenhead: return CoordinateFormatIds.builtinMaidenhead
        }
    }

    var legacyFormat: Int {
        switch self {
        case .ddd: return Int(FORMAT_DEGREES)
        case .ddm: return Int(FORMAT_MINUTES)
        case .dms: return Int(FORMAT_SECONDS)
        case .utm: return Int(FORMAT_UTM)
        case .olc: return Int(FORMAT_OLC)
        case .mgrs: return Int(FORMAT_MGRS)
        case .swissGrid: return Int(SWISS_GRID_FORMAT)
        case .swissGridPlus: return Int(SWISS_GRID_PLUS_FORMAT)
        case .maidenhead: return Int(MAIDENHEAD_FORMAT)
        }
    }

    var title: String {
        switch self {
        case .ddd: return localizedString("navigate_point_format_D")
        case .ddm: return localizedString("navigate_point_format_DM")
        case .dms: return localizedString("navigate_point_format_DMS")
        case .utm: return localizedString("navigate_point_format_UTM")
        case .olc: return localizedString("navigate_point_olc")
        case .mgrs: return localizedString("navigate_point_mgrs")
        case .swissGrid: return localizedString("navigate_point_format_swiss_grid")
        case .swissGridPlus: return localizedString("navigate_point_format_swiss_grid_plus")
        case .maidenhead: return localizedString("navigate_point_format_maidenhead")
        }
    }

    static func fromId(_ id: String?) -> BuiltInCoordinateFormat? {
        guard let normalized = CoordinateFormatIds.normalize(id) else { return nil }
        return allCases.first { $0.id == normalized }
    }

    static func resolve(_ id: String?) -> CoordinateFormat? {
        fromId(id)?.toCoordinateFormat()
    }
    
    func toCoordinateFormat() -> CoordinateFormat {
        .builtIn(id: id, title: title, legacyFormat: legacyFormat)
    }
}
