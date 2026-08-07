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

    var id: String {
        switch self {
        case .ddd: return CoordinateFormatIds.builtinDdd
        case .ddm: return CoordinateFormatIds.builtinDdm
        case .dms: return CoordinateFormatIds.builtinDms
        case .utm: return CoordinateFormatIds.builtinUtm
        case .olc: return CoordinateFormatIds.builtinOlc
        case .mgrs: return CoordinateFormatIds.builtinMgrs
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
        }
    }

    // Titles: follow task/Figma where they differ from Android short "UTM"/"OLC"
    var title: String {
        switch self {
        case .ddd: return localizedString("navigate_point_format_D")
        case .ddm: return localizedString("navigate_point_format_DM")
        case .dms: return localizedString("navigate_point_format_DMS")
        case .utm: return "Universal Transverse Mercator"
        case .olc: return localizedString("navigate_point_olc")
        case .mgrs: return "MGRS"
        }
    }

    func toCoordinateFormat() -> CoordinateFormat {
        .builtIn(id: id, title: title, legacyFormat: legacyFormat)
    }

    static func fromId(_ id: String?) -> BuiltInCoordinateFormat? {
        guard let normalized = CoordinateFormatIds.normalize(id) else { return nil }
        return allCases.first { $0.id == normalized }
    }

    static func resolve(_ id: String?) -> CoordinateFormat? {
        fromId(id)?.toCoordinateFormat()
    }
}
