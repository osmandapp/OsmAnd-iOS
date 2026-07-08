//
//  StarMapGlassBackground.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 08.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

enum StarMapGlassBackground {
    private static let tag = 9_001
    
    static func apply(to view: UIView, active: Bool, nightMode: Bool, cornerRadius: CGFloat) {
        if #available(iOS 26.0, *) {
            view.subviews.filter { $0.tag == tag }.forEach { $0.removeFromSuperview() }
            view.backgroundColor = .clear
            
            let baseColor = active
            ? UIColor.mapButtonBgColorActive
            : StarMapControlTheme.resolved(.mapButtonBgColorDefault, nightMode: nightMode)
            
            let glass = UIGlassEffect(style: .clear)
            let effectView = UIVisualEffectView(effect: glass)
            effectView.tag = tag
            effectView.isUserInteractionEnabled = false
            effectView.frame = view.bounds
            effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            effectView.layer.cornerRadius = cornerRadius
            effectView.clipsToBounds = true
            effectView.overrideUserInterfaceStyle = nightMode ? .dark : .light
            view.insertSubview(effectView, at: 0)
        } else {
            view.backgroundColor = active
            ? StarMapControlTheme.activeBackground()
            : StarMapControlTheme.defaultBackground(nightMode: nightMode, alpha: 0.5)
            view.layer.cornerRadius = cornerRadius
        }
    }
}
