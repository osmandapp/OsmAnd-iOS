//
//  AstroContextMenuLocalizer.swift
//  OsmAnd Maps
//
//  Created by Codex on 29.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation

enum AstroContextMenuLocalizer {
    static func label(_ key: String, fallback: String) -> String {
        let value = localizedString(key)
        return value == key ? fallback : value
    }
}

