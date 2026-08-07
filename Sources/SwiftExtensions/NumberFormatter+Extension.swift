//
//  NumberFormatter+Extension.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 24.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc
extension NumberFormatter {
    // 0.45 → "45%"
    static let percentFormatter: NumberFormatter = {
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        percentFormatter.maximumFractionDigits = 0
        percentFormatter.multiplier = 100
        return percentFormatter
    }()

    // Example for English locale: "1,234.5" -> 1234.5
    static let localizedNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: OAUtilities.currentLang() ?? Locale.current.identifier)
        return formatter
    }()
}
