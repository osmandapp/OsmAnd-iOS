//
//  SensorWidgetDataField.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 02.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

class SensorWidgetDataField: SensorDataField {
    let fieldType: WidgetType
    
    init(fieldType: WidgetType, nameId: String, unitNameId: String, numberValue: NSNumber?, stringValue: String?) {
        self.fieldType = fieldType
        super.init(nameId: nameId, unitNameId: unitNameId, numberValue: numberValue, stringValue: stringValue)
    }
    
    func getFieldType() -> WidgetType {
        fieldType
    }
    
    func getValueAndUnit(with valueUnitArray: NSMutableArray) -> (value: String, unit: String)? {
        guard valueUnitArray.count == 2,
              let value = valueUnitArray[0] as? String,
              let unit = valueUnitArray[1] as? String else {
            return nil
        }
        return (value: value, unit: unit)
    }
}

final class SensorSpeedWidgetDataField: SensorWidgetDataField {
    // SensorWidgetDataFieldType.BIKE_SPEED
    override func getFormattedValue() -> FormattedValue? {
        if let value = numberValue?.floatValue {
            let valueUnitArray: NSMutableArray = []
            OAOsmAndFormatter.getFormattedSpeed(value, valueUnitArray: valueUnitArray)
            if let result = getValueAndUnit(with: valueUnitArray) {
                return FormattedValue(valueSrc: 0, value: result.value, unit: result.unit)
            }
        }
        return nil
    }
}

final class SensorDistanceWidgetDataField: SensorWidgetDataField {
    // SensorWidgetDataFieldType.BIKE_DISTANCE
    override func getFormattedValue() -> FormattedValue? {
        if let value = numberValue?.floatValue {
            let valueUnitArray: NSMutableArray = []
            OAOsmAndFormatter.getFormattedDistance(value, forceTrailingZeroes: false, roundUp: false, valueUnitArray: valueUnitArray)
            if let result = getValueAndUnit(with: valueUnitArray) {
                return FormattedValue(valueSrc: 0, value: result.value, unit: result.unit)
            }
        }
        return nil
    }
}
