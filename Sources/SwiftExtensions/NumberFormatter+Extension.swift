//
//  NumberFormatter+Extension.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 24.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc
extension NumberFormatter {
    /* For example I use [NSNumberFormatter.percentFormatter stringFromNumber:@(_changedProfile.locationIconSize)] row in OAProfileAppearanceViewController to convert location icon size to percent type view
     */
    static let percentFormatter: NumberFormatter = {
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        percentFormatter.maximumFractionDigits = 0
        percentFormatter.multiplier = 100
        return percentFormatter
    }()
}
