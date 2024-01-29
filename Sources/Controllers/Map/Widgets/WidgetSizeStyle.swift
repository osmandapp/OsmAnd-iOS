//
//  WidgetSizeStyle.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 10.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers final class WidgetSizeStyleObjWrapper: NSObject {
    
    static func getLabelFontSizeFor(type: WidgetSizeStyle) -> CGFloat {
        type.labelFontSize
    }
    
    static func getValueFontSizeFor(type: WidgetSizeStyle) -> CGFloat {
        type.valueFontSize
    }
    
    static func getUnitsFontSizeFor(type: WidgetSizeStyle) -> CGFloat {
        type.unitsFontSize
    }
}

@objc enum WidgetSizeStyle: NSInteger {
    case small, medium, large
    
    var labelFontSize: CGFloat {
        switch self {
        case .small, .medium, .large: 11
        }
    }
    
    var valueFontSize: CGFloat {
        switch self {
        case .small: 22
        case .medium: 33
        case .large: 55
        }
    }
    
    var unitsFontSize: CGFloat {
        switch self {
        case .small, .medium, .large: 11
        }
    }
}
