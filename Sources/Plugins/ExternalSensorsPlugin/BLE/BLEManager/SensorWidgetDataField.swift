//
//  SensorWidgetDataField.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 02.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class SensorWidgetDataField: SensorDataField {
    let fieldType: WidgetType

    init(fieldType: WidgetType, nameId: String, unitNameId: String, numberValue: NSNumber?, stringValue: String?) {
        self.fieldType = fieldType
        super.init(nameId: nameId, unitNameId: unitNameId, numberValue: numberValue, stringValue: stringValue)
    }

    func getFieldType() -> WidgetType {
        fieldType
    }
}
