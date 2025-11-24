//
//  NumberFormatter+Extension.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 24.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc
extension NumberFormatter {
    static let percentFormatter: NumberFormatter = {
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        percentFormatter.maximumFractionDigits = 0
        percentFormatter.multiplier = 100
        return percentFormatter
    }()
}
