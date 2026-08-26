//
//  UIColor+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

extension UIColor {
    @objc var dark: UIColor { resolvedColor(with: .init(userInterfaceStyle: .dark)) }
    @objc var light: UIColor { resolvedColor(with: .init(userInterfaceStyle: .light)) }
    @objc var currentMapThemeColor: UIColor { OAAppSettings.sharedManager().nightMode ? dark : light }
    @objc var activeMapThemeColor: UIColor {
        OAAppSettings.sharedManager().activeMapNightMode ? dark : light
    }
}
