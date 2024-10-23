//
//  UIFont+Extension.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 16/10/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

extension UIFont {
    static func monospacedFont(at size: CGFloat, withTextStyle style: TextStyle) -> UIFont {
        let bodyFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let bodyMonospacedNumbersFontDescriptor = bodyFontDescriptor.addingAttributes(
            [
                UIFontDescriptor.AttributeName.featureSettings: [
                    [
                        UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                        UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector
                    ]
                ]
            ])
        return UIFont(descriptor: bodyMonospacedNumbersFontDescriptor, size: size)
    }
}
