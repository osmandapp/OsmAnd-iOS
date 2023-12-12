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
    var buttonBgColorDisabled: UIColor { getColorTheme(with: UIColor.buttonBgColorDisabled) }
    var buttonBgColorDisruptive: UIColor { getColorTheme(with: UIColor.buttonBgColorDisruptive) }
    var buttonBgColorPrimary: UIColor { getColorTheme(with: UIColor.buttonBgColorPrimary) }
    var buttonBgColorSecondary: UIColor { getColorTheme(with: UIColor.buttonBgColorSecondary) }
    var buttonBgColorTap: UIColor { getColorTheme(with: UIColor.buttonBgColorTap) }
    var buttonBgColorTertiary: UIColor { getColorTheme(with: UIColor.buttonBgColorTertiary) }
    var buttonTextColorPrimary: UIColor { getColorTheme(with: UIColor.buttonTextColorPrimary) }
    var buttonTextColorSecondary: UIColor { getColorTheme(with: UIColor.buttonTextColorSecondary) }
    var groupBgColor: UIColor { getColorTheme(with: UIColor.groupBgColor) }
    var iconColorActive: UIColor { getColorTheme(with: UIColor.iconColorActive) }
    var iconColorDefault: UIColor { getColorTheme(with: UIColor.iconColorDefault) }
    var iconColorSecondary: UIColor { getColorTheme(with: UIColor.iconColorSecondary) }
    var iconColorSelected: UIColor { getColorTheme(with: UIColor.iconColorSelected) }
    var iconColorTertiary: UIColor { getColorTheme(with: UIColor.iconColorTertiary) }
    var iconColorDisabled: UIColor { getColorTheme(with: UIColor.iconColorDisabled) }
    var separatorColor: UIColor { getColorTheme(with: UIColor.separatorColor) }
    var textColorActive: UIColor { getColorTheme(with: UIColor.textColorActive) }
    var textColorPrimary: UIColor { getColorTheme(with: UIColor.textColorPrimary) }
    var textColorSecondary: UIColor { getColorTheme(with: UIColor.textColorSecondary) }
    var textColorTertiary: UIColor { getColorTheme(with: UIColor.textColorTertiary) }
    var viewBgColor: UIColor { getColorTheme(with: UIColor.viewBgColor) }
    var navBarBgColorPrimary: UIColor { getColorTheme(with: UIColor.navBarBgColorPrimary) }
    var navBarTextColorPrimary: UIColor { getColorTheme(with: UIColor.navBarTextColorPrimary) }
    var groupBgColorSecondary: UIColor { getColorTheme(with: UIColor.groupBgColorSecondary) }
    var cellBgColorSelected: UIColor { getColorTheme(with: UIColor.cellBgColorSelected) }
    var contextMenuButtonBgColor: UIColor { getColorTheme(with: UIColor.contextMenuButtonBgColor) }
    var weatherSliderLabelBgColor: UIColor { getColorTheme(with: UIColor.weatherSliderLabelBgColor) }
    var buttonIconColorPrimary: UIColor { getColorTheme(with: UIColor.buttonIconColorPrimary) }
    var buttonIconColorSecondary: UIColor { getColorTheme(with: UIColor.buttonIconColorSecondary) }
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
