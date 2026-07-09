//
//  StarMapButton.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

enum StarMapControlTheme {
    static var borderColor: UIColor {
        UIColor(rgb: color_on_map_icon_border_color)
    }
    
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
}

@objcMembers
class StarMapButton: OAHudButton {
    var showsHudChrome = true

    var active = false {
        didSet { updateTheme() }
    }

    var nightMode = false {
        didSet { updateTheme() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func setIcon(iconName: String, accessibilityLabel: String? = nil) {
        setImage(AstroIcon.template(iconName), for: .normal)
        self.accessibilityLabel = accessibilityLabel
        updateTheme()
    }

    func updateTheme() {
        guard showsHudChrome else {
            applyPlainTheme()
            return
        }

        if active {
            unpressedColorDay = .mapButtonBgColorActive.light
            unpressedColorNight = .mapButtonBgColorActive.dark
            tintColorDay = .white
            tintColorNight = .white
            borderWidthDay = 0
            borderWidthNight = 0
        } else {
            unpressedColorDay = .mapButtonBgColorDefault.light
            unpressedColorNight = .mapButtonBgColorDefault.dark
            tintColorDay = .mapButtonIconColorDefault.light
            tintColorNight = .mapButtonIconColorDefault.dark
            borderWidthDay = 0
            borderWidthNight = 2
        }

        updateColors(forPressedState: isHighlighted)
        if active {
            backgroundColor = StarMapControlTheme.activeBackground(alpha: 0.5)
        }
    }

    private func applyDefaultAppearanceParams() {
        let helper = OAMapButtonsHelper.sharedInstance()
        var size = helper.getDefaultSizePref().get()
        if size <= 0 { size = MapButtonState.defaultSizeDp }

        var cornerRadius = helper.getDefaultCornerRadiusPref().get()
        if cornerRadius < 0 { cornerRadius = MapButtonState.roundRadiusDp }

        var glassStyle: Int32
        var opacity: Double
        if #available(iOS 26.0, *) {
            glassStyle = Int32(UIGlassEffect.Style.clear.rawValue)
            opacity = 0.5
        } else {
            glassStyle = MapButtonState.defaultGlassStyle
            opacity = helper.getDefaultOpacityPref().get()
            if opacity < 0 {
                opacity = MapButtonState.opaqueAlpha
            }
        }

        setCustomAppearanceParams(ButtonAppearanceParams(
            iconName: nil,
            size: Int32(size),
            opacity: opacity,
            cornerRadius: Int32(cornerRadius),
            glassStyle: glassStyle
        ))
    }

    private func applyPlainTheme() {
        backgroundColor = .clear
        layer.borderWidth = 0
        layer.shadowOpacity = 0
        
        let color = active
        ? StarMapControlTheme.activeForeground(nightMode: nightMode)
        : StarMapControlTheme.foreground(active: false, nightMode: nightMode)
        
        tintColor = color
        tintColorDay = color
        tintColorNight = color
        
        updateColors(forPressedState: isHighlighted)
    }
    
    private func commonInit() {
        imageView?.contentMode = .scaleAspectFit
        applyDefaultAppearanceParams()
        updateTheme()
    }
}
