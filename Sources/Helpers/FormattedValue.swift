//
//  FormattedValue.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 30.10.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class FormattedValue: NSObject {
    let value: String
    let unit: String?
    let valueSrc: Float
    
    private let separateWithSpace: Bool
    
    init(valueSrc: Float, value: String, unit: String?) {
        self.value = value
        self.valueSrc = valueSrc
        self.unit = unit
        self.separateWithSpace = true
    }
    
    init(valueSrc: Float, value: String, unit: String?, separateWithSpace: Bool) {
        self.value = value
        self.valueSrc = valueSrc
        self.unit = unit
        self.separateWithSpace = separateWithSpace
    }
}
