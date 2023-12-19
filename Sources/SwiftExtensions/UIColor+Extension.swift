//
//  UIColor+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

extension UIColor {
    @objc static var buttonBgColorDisabled: UIColor { UIColor(named: #function)! }
    @objc static var buttonBgColorDisruptive: UIColor { UIColor(named: #function)! }
    @objc static var buttonBgColorPrimary: UIColor { UIColor(named: #function)! }
    @objc static var buttonBgColorSecondary: UIColor { UIColor(named: #function)! }
    @objc static var buttonBgColorTap: UIColor { UIColor(named: #function)! }
    @objc static var buttonBgColorTertiary: UIColor { UIColor(named: #function)! }
    @objc static var buttonTextColorPrimary: UIColor { UIColor(named: #function)! }
    @objc static var buttonTextColorSecondary: UIColor { UIColor(named: #function)! }
    @objc static var groupBgColor: UIColor { UIColor(named: #function)! }
    @objc static var iconColorActive: UIColor { UIColor(named: #function)! }
    @objc static var iconColorDefault: UIColor { UIColor(named: #function)! }
    @objc static var iconColorSecondary: UIColor { UIColor(named: #function)! }
    @objc static var iconColorSelected: UIColor { UIColor(named: #function)! }
    @objc static var iconColorTertiary: UIColor { UIColor(named: #function)! }
    @objc static var iconColorDisabled: UIColor { UIColor(named: #function)! }
    @objc static var separatorColor: UIColor { UIColor(named: #function)! }
    @objc static var textColorActive: UIColor { UIColor(named: #function)! }
    @objc static var textColorPrimary: UIColor { UIColor(named: #function)! }
    @objc static var textColorSecondary: UIColor { UIColor(named: #function)! }
    @objc static var textColorTertiary: UIColor { UIColor(named: #function)! }
    @objc static var viewBgColor: UIColor { UIColor(named: #function)! }
    @objc static var navBarBgColorPrimary: UIColor { UIColor(named: #function)! }
    @objc static var navBarTextColorPrimary: UIColor { UIColor(named: #function)! }
    @objc static var groupBgColorSecondary: UIColor { UIColor(named: #function)! }
    @objc static var cellBgColorSelected: UIColor { UIColor(named: #function)! }
    @objc static var contextMenuButtonBgColor: UIColor { UIColor(named: #function)! }
    @objc static var weatherSliderLabelBgColor: UIColor { UIColor(named: #function)! }
    @objc static var buttonIconColorPrimary: UIColor { UIColor(named: #function)! }
    @objc static var buttonIconColorSecondary: UIColor { UIColor(named: #function)! }

    @objc static var chartAxisValueBgColor: UIColor { UIColor(named: #function)! }
    @objc static var chartAxisGridLineColor: UIColor { UIColor(named: #function)! }
    @objc static var chartSliderLabelBgColor: UIColor { UIColor(named: #function)! }
    @objc static var chartSliderLabelStrokeColor: UIColor { UIColor(named: #function)! }
    @objc static var chartSliderLineColor: UIColor { UIColor(named: #function)! }

    @objc static var chartTextColorAxisX: UIColor { UIColor(named: #function)! }
    @objc static var chartTextColorElevation: UIColor { UIColor(named: #function)! }
    @objc static var chartTextColorSlope: UIColor { UIColor(named: #function)! }
    @objc static var chartTextColorSpeed: UIColor { UIColor(named: #function)! }
    @objc static var chartTextColorBicycleCadence: UIColor { UIColor(named: #function)! }
    @objc static var chartTextColorBicyclePower: UIColor { UIColor(named: #function)! }
    @objc static var chartTextColorHeartRate: UIColor { UIColor(named: #function)! }
    @objc static var chartTextColorSpeedSensor: UIColor { UIColor(named: #function)! }

    @objc static var chartLineColorElevation: UIColor { UIColor(named: #function)! }
    @objc static var chartLineColorSlope: UIColor { UIColor(named: #function)! }
    @objc static var chartLineColorSpeed: UIColor { UIColor(named: #function)! }
    @objc static var chartLineColorBicycleCadence: UIColor { UIColor(named: #function)! }
    @objc static var chartLineColorBicyclePower: UIColor { UIColor(named: #function)! }
    @objc static var chartLineColorHeartRate: UIColor { UIColor(named: #function)! }
    @objc static var chartLineColorSpeedSensor: UIColor { UIColor(named: #function)! }
}

extension UIColor {
    var dark: UIColor { resolvedColor(with: .init(userInterfaceStyle: .dark)) }
    var light: UIColor { resolvedColor(with: .init(userInterfaceStyle: .light)) }
}
