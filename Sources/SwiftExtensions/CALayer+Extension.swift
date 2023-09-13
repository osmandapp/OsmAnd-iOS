//
//  CALayer+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 28.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

extension CALayer {
    
    @objc func addWidgetLayerDecorator(mask: CACornerMask) {
        borderWidth = 2
        cornerRadius = 7
        borderColor = UIColor.lightGray.cgColor
        maskedCorners = mask
    }
}
