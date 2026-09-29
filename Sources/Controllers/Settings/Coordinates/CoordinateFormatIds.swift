//
//  CoordinateFormatIds.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 07.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import OsmAndShared

enum CoordinateFormatIds {
    private static let shared = OsmAndShared.CoordinateFormatIds.shared

    static let builtinDdd = shared.BUILTIN_DDD
    static let builtinDdm = shared.BUILTIN_DDM
    static let builtinDms = shared.BUILTIN_DMS
    static let builtinUtm = shared.BUILTIN_UTM
    static let builtinOlc = shared.BUILTIN_OLC
    static let builtinMgrs = shared.BUILTIN_MGRS
    static let builtinSwissGrid = shared.BUILTIN_SWISS_GRID
    static let builtinSwissGridPlus = shared.BUILTIN_SWISS_GRID_PLUS
    static let builtinMaidenhead = shared.BUILTIN_MAIDENHEAD

    static let epsgPrefix = shared.EPSG_PREFIX

    static let defaultFormatIds = shared.DEFAULT_FORMAT_IDS
    static let allBuiltInFormatIds = shared.ALL_BUILT_IN_FORMAT_IDS

    static func epsg(_ code: Int) -> String {
        shared.epsg(code: Int32(code))
    }

    static func normalize(_ id: String?) -> String? {
        shared.normalize(id: id)
    }

    static func epsgCode(_ id: String?) -> Int? {
        shared.getEpsgCode(id: id)?.intValue
    }

    static func fromOldFormat(_ format: Int) -> String? {
        switch format {
        case Int(FORMAT_DEGREES): return builtinDdd
        case Int(FORMAT_MINUTES): return builtinDdm
        case Int(FORMAT_SECONDS): return builtinDms
        case Int(FORMAT_UTM): return builtinUtm
        case Int(FORMAT_OLC): return builtinOlc
        case Int(FORMAT_MGRS): return builtinMgrs
        case Int(SWISS_GRID_FORMAT): return builtinSwissGrid
        case Int(SWISS_GRID_PLUS_FORMAT): return builtinSwissGridPlus
        case Int(MAIDENHEAD_FORMAT): return builtinMaidenhead
        default: return nil
        }
    }
}
