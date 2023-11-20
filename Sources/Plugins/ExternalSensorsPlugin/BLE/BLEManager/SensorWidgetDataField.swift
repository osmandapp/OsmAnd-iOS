//
//  SensorWidgetDataField.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 02.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

class SensorWidgetDataField: SensorDataField {
    let fieldType: WidgetType

    init(fieldType: WidgetType, nameId: String, unitNameId: String, numberValue: NSNumber?, stringValue: String?) {
        self.fieldType = fieldType
        super.init(nameId: nameId, unitNameId: unitNameId, numberValue: numberValue, stringValue: stringValue)
    }

    func getFieldType() -> WidgetType {
        fieldType
    }
}


class SensorSpeedWidgetDataField: SensorWidgetDataField {
    // SensorWidgetDataFieldType.BIKE_SPEED
    override func getFormattedValue() -> FormattedValue? {
        if let value = numberValue?.floatValue {
            if let formattedSpeed = OAOsmAndFormatter.getFormattedSpeed(value) {
                return FormattedValue(valueSrc: 0, value: formattedSpeed, unit: nil)
            }
        }
        return nil
    }
}

class SensorDistanceWidgetDataField: SensorWidgetDataField {
    // SensorWidgetDataFieldType.BIKE_DISTANCE
    override func getFormattedValue() -> FormattedValue? {
        if let value = numberValue?.floatValue {
            if let formattedDistance = OAOsmAndFormatter.getFormattedDistance(value, forceTrailingZeroes: false) {
                return FormattedValue(valueSrc: 0, value: formattedDistance, unit: nil)
            }
        }
        return nil
    }
}

