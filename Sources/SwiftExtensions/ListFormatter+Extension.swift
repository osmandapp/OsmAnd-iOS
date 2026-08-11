//
//  ListFormatter+Extension.swift
//  OsmAnd
//
//  Created by OsmAnd on 07.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

extension ListFormatter {
    // Example for English locale: ["1 hour", "5 minutes"] -> "1 hour and 5 minutes"
    static let accessibilityFormatter: ListFormatter = {
        let formatter = ListFormatter()
        formatter.locale = .current
        return formatter
    }()
}
