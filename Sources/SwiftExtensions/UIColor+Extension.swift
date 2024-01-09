//
//  UIColor+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

extension UIColor {
    var dark: UIColor { resolvedColor(with: .init(userInterfaceStyle: .dark)) }
    var light: UIColor { resolvedColor(with: .init(userInterfaceStyle: .light)) }
}
