//
//  StarMapButton.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

enum StarMapControlTheme {
    static func resolved(_ color: UIColor, nightMode: Bool) -> UIColor {
        nightMode ? color.dark : color.light
    }

    static func defaultBackground(nightMode: Bool, alpha: CGFloat) -> UIColor {
        resolved(.mapButtonBgColorDefault, nightMode: nightMode).withAlphaComponent(alpha)
    }

    static func activeBackground(alpha: CGFloat = 1) -> UIColor {
        UIColor.mapButtonBgColorActive.withAlphaComponent(alpha)
    }

    static func foreground(active: Bool, nightMode: Bool) -> UIColor {
        active ? .white : resolved(.mapButtonIconColorDefault, nightMode: nightMode)
    }

    static func activeForeground(nightMode: Bool) -> UIColor {
        resolved(.mapButtonIconColorActive, nightMode: nightMode)
    }

    static func textColor(nightMode: Bool) -> UIColor {
        resolved(.textColorPrimary, nightMode: nightMode)
    }

    static func borderWidth(active: Bool, nightMode: Bool) -> CGFloat {
        active ? 0 : (nightMode ? 2 : 0)
    }

    static var borderColor: UIColor {
        UIColor(rgb: color_on_map_icon_border_color)
    }
}

class StarMapButton: UIButton {
    var active = false {
        didSet { updateTheme() }
    }
    var nightMode = false {
        didSet { updateTheme() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView?.contentMode = .scaleAspectFit
        updateTheme()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        imageView?.contentMode = .scaleAspectFit
        updateTheme()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2.0
    }

    func updateTheme() {
        tintColor = StarMapControlTheme.foreground(active: active, nightMode: nightMode)
        backgroundColor = active
            ? StarMapControlTheme.activeBackground()
            : StarMapControlTheme.defaultBackground(nightMode: nightMode, alpha: 0.86)
        layer.cornerRadius = min(bounds.width, bounds.height) / 2.0
        layer.borderWidth = StarMapControlTheme.borderWidth(active: active, nightMode: nightMode)
        layer.borderColor = StarMapControlTheme.borderColor.cgColor
    }

    func setColorFilter(_ color: UIColor) {
        tintColor = color
    }

    func setIcon(iconName: String, accessibilityLabel: String? = nil) {
        setImage(AstroIcon.template(iconName), for: .normal)
        self.accessibilityLabel = accessibilityLabel
    }
}
