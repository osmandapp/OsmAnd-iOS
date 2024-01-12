//
//  WidgetSizeStyle.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 10.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

extension OABaseWidgetView {
    var widgetSizeStyle: WidgetSizeStyle {
        return .medium
    }
}

@objc enum WidgetSizeStyle: Int {
    case regular, small, medium, large
    
    var labelFont: UIFont {
        switch self {
#warning("regular")
        case .regular: UIFont.systemFont(ofSize: 20)
        case .small: UIFont.systemFont(ofSize: 22)
        case .medium: UIFont.systemFont(ofSize: 33)
        case .large: UIFont.systemFont(ofSize: 55)
        }
    }
    
    var valueFont: UIFont {
        switch self {
#warning("regular")
        case .regular: UIFont.systemFont(ofSize: 20)
        case .small, .medium, .large: UIFont.systemFont(ofSize: 11)
        }
    }
    
    var unitsFont: UIFont {
        switch self {
#warning("regular")
        case .regular: UIFont.systemFont(ofSize: 20)
        case .small, .medium, .large: UIFont.systemFont(ofSize: 11)
        }
    }
    
    var minHeight: CGFloat {
        switch self {
        case .regular: 44
        case .small: 44
        case .medium: 66
        case .large: 88
        }
    }
}
