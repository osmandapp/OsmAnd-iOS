//
//  CALayer+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 28.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

extension CALayer {
    @objc func addWidgetLayerDecorator(mask: CACornerMask) {
        shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.31).cgColor
        shadowOpacity = 1
        shadowRadius = 2
        shadowOffset = CGSize(width: 0, height: 2)
        borderWidth = 2
        cornerRadius = 7
        masksToBounds = true
        borderColor =  UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 0.4).cgColor
        maskedCorners = mask//[.layerMinXMinYCorner, .layerMinXMaxYCorner]
        shouldRasterize = true
        rasterizationScale = UIScreen.main.scale
    }
}
