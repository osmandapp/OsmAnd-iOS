//
//  Theme.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc enum Theme: Int {
    case system, light, dark
    
    var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

extension Theme {
    private func getColorTheme(with color: UIColor) -> UIColor {
        switch self {
        case .system:
            return color
        case .light:
            return color.light
        case .dark:
            return color.dark
        }
    }
}
