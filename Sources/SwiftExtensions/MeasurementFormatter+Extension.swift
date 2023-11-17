//
//  MeasurementFormatter+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 15.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

extension MeasurementFormatter {
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
