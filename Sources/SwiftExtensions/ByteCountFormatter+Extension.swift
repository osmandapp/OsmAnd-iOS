//
//  ByteCountFormatter+Extension.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

extension ByteCountFormatter {
    static let fileSizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.allowsNonnumericFormatting = false
        return formatter
    }()
}
