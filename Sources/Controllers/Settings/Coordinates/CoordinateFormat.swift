//
//  CoordinateFormat.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 07.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

enum CoordinateFormatType {
    case builtIn
    case epsg
    case unknown
}

struct CoordinateFormat {
    let id: String
    let type: CoordinateFormatType
    let title: String
    let subtitle: String?
    let epsgCode: Int?
    let legacyFormat: Int?
    let isDeprecated: Bool
    let isResolved: Bool

    static func builtIn(id: String, title: String, legacyFormat: Int) -> CoordinateFormat {
        CoordinateFormat(
            id: id,
            type: .builtIn,
            title: title,
            subtitle: nil,
            epsgCode: nil,
            legacyFormat: legacyFormat,
            isDeprecated: false,
            isResolved: true
        )
    }
    
    static func epsg(code: Int, title: String?, subtitle: String?, isDeprecated: Bool) -> CoordinateFormat {
        let fallback = "EPSG:\(code)"
        return CoordinateFormat(
            id: CoordinateFormatIds.epsg(code),
            type: .epsg,
            title: title?.isEmpty == false ? title! : fallback,
            subtitle: subtitle,
            epsgCode: code,
            legacyFormat: nil,
            isDeprecated: isDeprecated,
            isResolved: true
        )
    }

    static func unresolvedEpsg(code: Int) -> CoordinateFormat {
        CoordinateFormat(
            id: CoordinateFormatIds.epsg(code),
            type: .epsg,
            title: "EPSG:\(code)",
            subtitle: nil,
            epsgCode: code,
            legacyFormat: nil,
            isDeprecated: false,
            isResolved: false
        )
    }

    static func unknown(id: String) -> CoordinateFormat {
        CoordinateFormat(
            id: id,
            type: .unknown,
            title: id,
            subtitle: nil,
            epsgCode: nil,
            legacyFormat: nil,
            isDeprecated: false,
            isResolved: false
        )
    }
}
