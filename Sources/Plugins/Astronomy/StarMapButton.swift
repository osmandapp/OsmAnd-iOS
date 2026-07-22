//
//  StarMapButton.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

enum StarMapControlTheme {
    static let defaultBackgroundAlpha: CGFloat = 0.7
    
    static func resolved(_ color: UIColor, nightMode: Bool) -> UIColor {
        nightMode ? color.dark : color.light
    }

    static func defaultBackground(nightMode: Bool, alpha: CGFloat) -> UIColor {
        resolved(.mapButtonBgColorDefault, nightMode: nightMode).withAlphaComponent(alpha)
    }
    
    static func pressedBackground(nightMode: Bool, alpha: CGFloat) -> UIColor {
        resolved(.mapButtonBgColorTap, nightMode: nightMode).withAlphaComponent(alpha)
    }

    static func activeBackground(alpha: CGFloat = 1) -> UIColor {
        .mapButtonBgColorActive.withAlphaComponent(alpha)
    }

    static func foreground(active: Bool, nightMode: Bool) -> UIColor {
        active ? .white : resolved(.mapButtonIconColorDefault, nightMode: nightMode)
    }

    static func activeForeground(nightMode: Bool) -> UIColor {
        resolved(.mapButtonIconColorActive, nightMode: nightMode)
    }
    
    static func border(nightMode: Bool) -> UIColor {
        resolved(.mapButtonBorder, nightMode: nightMode)
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
    
    override func updateColors(forPressedState isPressed: Bool) {
        super.updateColors(forPressedState: isPressed)
        if showsHudChrome {
            backgroundColor = backgroundColor?.withAlphaComponent(StarMapControlTheme.defaultBackgroundAlpha)
        }
    }

    func setIcon(icon: UIImage?, accessibilityLabel: String? = nil) {
        setImage(icon, for: .normal)
        self.accessibilityLabel = accessibilityLabel
        updateTheme()
    }

    func updateTheme() {
        if active {
            unpressedColorDay = .mapButtonBgColorActive.light
            unpressedColorNight = .mapButtonBgColorActive.dark
            tintColorDay = .white
            tintColorNight = .white
            borderWidthDay = 0
            borderWidthNight = 2
        } else {
            unpressedColorDay = .mapButtonBgColorDefault.light
            unpressedColorNight = .mapButtonBgColorDefault.dark
            tintColorDay = .mapButtonIconColorDefault.light
            tintColorNight = .mapButtonIconColorDefault.dark
            borderWidthDay = 0
            borderWidthNight = 2
        }
        
        guard showsHudChrome else {
            applyPlainTheme()
            return
        }

        updateColors(forPressedState: isHighlighted)
        if active {
            backgroundColor = StarMapControlTheme.activeBackground(alpha: StarMapControlTheme.defaultBackgroundAlpha)
        } else {
            backgroundColor = backgroundColor?.withAlphaComponent(StarMapControlTheme.defaultBackgroundAlpha)
        }
    }

    private func applyDefaultAppearanceParams() {
        let helper = OAMapButtonsHelper.sharedInstance()
        var size = helper.getDefaultSizePref().get()
        if size <= 0 { size = MapButtonState.defaultSizeDp }

        var cornerRadius = helper.getDefaultCornerRadiusPref().get()
        if cornerRadius < 0 { cornerRadius = MapButtonState.roundRadiusDp }

        var glassStyle = MapButtonState.defaultGlassStyle
        if #available(iOS 26.0, *) {
            glassStyle = Int32(UIGlassEffect.Style.clear.rawValue)
        }
        let opacity = Double(StarMapControlTheme.defaultBackgroundAlpha)
        
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
        layer.borderWidth = nightMode ? 2 : 0
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
