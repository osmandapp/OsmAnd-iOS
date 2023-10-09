//
//  UIColor+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

extension UIColor {
    static var buttonBgColorDisabled: UIColor { UIColor(named: #function)! }
    static var buttonBgColorDisruptive: UIColor { UIColor(named: #function)! }
    static var buttonBgColorPrimary: UIColor { UIColor(named: #function)! }
    static var buttonBgColorSecondary: UIColor { UIColor(named: #function)! }
#warning ("add all colors from asset")
}

extension UIColor {
    var dark: UIColor { resolvedColor(with: .init(userInterfaceStyle: .dark)) }
    var light: UIColor { resolvedColor(with: .init(userInterfaceStyle: .light)) }
}
