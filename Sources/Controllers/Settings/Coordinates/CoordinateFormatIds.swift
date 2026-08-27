//
//  CoordinateFormatIds.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 07.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

enum CoordinateFormatIds {
    static let builtinDdd = "builtin:ddd"
    static let builtinDdm = "builtin:ddm"
    static let builtinDms = "builtin:dms"
    static let builtinUtm = "builtin:utm"
    static let builtinOlc = "builtin:olc"
    static let builtinMgrs = "builtin:mgrs"

    static let epsgPrefix = "epsg:"

    static let defaultFormatIds: [String] = [
        builtinDdd, builtinDdm, builtinDms, builtinUtm, builtinOlc
    ]

    static let allBuiltInFormatIds: [String] = [
        builtinDdd, builtinDdm, builtinDms, builtinUtm, builtinOlc, builtinMgrs
    ]

    private static let builtInIdSet = Set(allBuiltInFormatIds)

    static func epsg(_ code: Int) -> String {
        "\(epsgPrefix)\(code)"
    }

    static func normalize(_ id: String?) -> String? {
        guard let trimmed = id?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !trimmed.isEmpty else { return nil }
        if builtInIdSet.contains(trimmed) {
            return trimmed
        }
        if let code = epsgCode(trimmed) {
            return epsg(code)
        }
        return nil
    }

    static func epsgCode(_ id: String?) -> Int? {
        guard let trimmed = id?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              trimmed.hasPrefix(epsgPrefix),
              let code = Int(trimmed.dropFirst(epsgPrefix.count)),
              code > 0 else { return nil }
        return code
    }

    static func fromOldFormat(_ format: Int) -> String? {
        switch format {
        case Int(FORMAT_DEGREES): return builtinDdd
        case Int(FORMAT_MINUTES): return builtinDdm
        case Int(FORMAT_SECONDS): return builtinDms
        case Int(FORMAT_UTM): return builtinUtm
        case Int(FORMAT_OLC): return builtinOlc
        case Int(FORMAT_MGRS): return builtinMgrs
        default: return nil
        }
    }
}
