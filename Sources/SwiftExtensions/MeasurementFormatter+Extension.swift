//
//  MeasurementFormatter+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 15.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

extension MeasurementFormatter {
    // Example for English locale: 120 meters -> "120 meters"
    static let accessibilityIntegerFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .long
        formatter.unitOptions = .providedUnit
        formatter.locale = .current
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()

    // Example for English locale: 1.5 kilometers -> "1.5 kilometers"
    static let accessibilityDecimalFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .long
        formatter.unitOptions = .providedUnit
        formatter.locale = .current
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()

    static func numeric(maximumFractionDigits: Int = 1,
                        minimumIntegerDigits: Int = 1) -> MeasurementFormatter {
        let measurementFormatter = MeasurementFormatter()
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = maximumFractionDigits
        numberFormatter.minimumIntegerDigits = minimumIntegerDigits
        measurementFormatter.numberFormatter = numberFormatter
        return measurementFormatter
    }
}
