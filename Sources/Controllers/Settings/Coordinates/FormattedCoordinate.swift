//
//  FormattedCoordinate.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 13.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

struct FormattedCoordinate {
    let format: CoordinateFormat
    let text: String

    var displayPrefix: String? {
        if let code = format.epsgCode {
            return "EPSG:\(code)"
        }
        if format.type == .unknown || format.id.isEmpty {
            return nil
        }
        return format.title
    }

    static func plain(_ text: String) -> FormattedCoordinate {
        FormattedCoordinate(format: .unknown(id: ""), text: text)
    }
}
