//
//  CALayer+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 28.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

extension CALayer {
    @objc func addWidgetLayerDecorator(mask: CACornerMask,
                                       isNighTheme: Bool) {
        borderWidth = 2
        cornerRadius = 7
        borderColor = isNighTheme ? UIColor.widgetBgStroke.dark.cgColor : UIColor.widgetBgStroke.light.cgColor
        maskedCorners = mask
    }
}
