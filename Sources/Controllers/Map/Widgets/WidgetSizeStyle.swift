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
    
    static func getTopBottomPadding(type: WidgetSizeStyle) -> CGFloat {
        type.topBottomPadding
    }
    
    static func getPaddingBetweenIconAdndValue(type: WidgetSizeStyle) -> CGFloat {
        type.paddingBetweenIconAdndValue
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
    
    var topBottomPadding: CGFloat {
        switch self {
        case .small: 7
        case .medium: 10
        case .large: 12
        }
    }
    
    var paddingBetweenIconAdndValue: CGFloat {
        switch self {
        case .small: 6
        case .medium, .large: 12
        }
    }
}
