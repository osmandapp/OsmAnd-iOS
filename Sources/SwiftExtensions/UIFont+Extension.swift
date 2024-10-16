//
//  UIFont+Extension.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 16/10/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

extension UIFont {
    
    @objc static func digitsOnlyMonospacedFont(size: CGFloat) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size)
        let fontDescriptor = systemFont.fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                    UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector
                ]
            ]
        ])
        return UIFont(descriptor: fontDescriptor, size: size)
    }
}
