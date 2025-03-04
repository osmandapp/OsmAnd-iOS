//
//  DateFormatter+Extension.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 04.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

extension DateFormatter {
    static let dateStyleMedium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale.current
        return formatter
    }()
}
