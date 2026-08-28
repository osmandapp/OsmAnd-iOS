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

    private static let countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    static func localizedCount(_ count: NSNumber) -> String {
        countFormatter.string(from: count) ?? count.stringValue
    }

    @nonobjc
    static func localizedCount<T: BinaryInteger>(_ count: T) -> String {
        if let signedCount = Int64(exactly: count) {
            return localizedCount(NSNumber(value: signedCount))
        }

        if let unsignedCount = UInt64(exactly: count) {
            return localizedCount(NSNumber(value: unsignedCount))
        }

        return String(describing: count)
    }
}
