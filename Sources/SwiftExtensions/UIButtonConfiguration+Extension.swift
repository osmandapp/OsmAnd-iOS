//
//  UIButtonConfigurationExtension.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 23.02.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

extension UIButton.Configuration {
    static func purchasePlanButtonConfiguration(title: String) -> UIButton.Configuration {
        let isRTL = UITraitCollection.current.layoutDirection == .rightToLeft
        let arrow = isRTL ? "arrow.left" : "arrow.right"
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: arrow)
        config.imagePlacement = isRTL ? .leading : .trailing
        config.imagePadding = 6
        config.baseForegroundColor = .buttonTextColorSecondary
        config.background.backgroundColor = .buttonBgColorTertiary
        return config
    }
}
