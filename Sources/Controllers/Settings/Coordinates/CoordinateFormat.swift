//
//  CoordinateFormat.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 07.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import OsmAndShared

typealias CoordinateFormat = OsmAndShared.CoordinateFormat
typealias CoordinateFormatType = OsmAndShared.CoordinateFormatType

extension CoordinateFormat {
    static func builtIn(id: String, title: String, legacyFormat: Int) -> CoordinateFormat {
        companion.builtIn(id: id, title: title, legacyFormat: Int32(legacyFormat))
    }

    static func epsg(code: Int, title: String?, subtitle: String?, isDeprecated: Bool) -> CoordinateFormat {
        companion.epsg(code: Int32(code), title: title, subtitle: subtitle, isDeprecated: isDeprecated)
    }

    static func unresolvedEpsg(code: Int) -> CoordinateFormat {
        companion.unresolvedEpsg(code: Int32(code))
    }

    static func unknown(id: String) -> CoordinateFormat {
        companion.unknown(id: id)
    }

    var epsgCodeValue: Int? {
        epsgCode?.intValue
    }

    var legacyFormatValue: Int? {
        legacyFormat?.intValue
    }
}
