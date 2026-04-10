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
    
    static func proBannerButtonConfiguration(image: UIImage?) -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.title = nil
        config.image = nil
        config.background.image = image
        config.background.imageContentMode = .scaleAspectFill
        config.background.cornerRadius = 8.0
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 35, bottom: 16, trailing: 35)
        config.cornerStyle = .fixed
        return config
    }
    
    static func mapsPlusBannerButtonConfiguration(image: UIImage?) -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.title = nil
        config.image = nil
        config.background.image = image
        config.background.imageContentMode = .scaleAspectFill
        config.background.cornerRadius = 8.0
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 45.5, bottom: 16, trailing: 45.5)
        config.cornerStyle = .fixed
        return config
    }
}
