//
//  Theme.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

enum Theme: Int {
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
    var buttonBgColorDisabled: UIColor { getColorTheme(with: UIColor.buttonBgColorDisabled) }
    var buttonBgColorDisruptive: UIColor { getColorTheme(with: UIColor.buttonBgColorDisruptive) }
#warning("add all color schemes")
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

extension UIColor {
    var dark: UIColor { resolvedColor(with: .init(userInterfaceStyle: .dark)) }
    var light: UIColor { resolvedColor(with: .init(userInterfaceStyle: .light)) }
}

extension UIWindow {
    static var key: UIWindow! {
#warning("will change after use Scene")
        return UIApplication.shared.windows.first { $0.isKeyWindow }
    }
}
