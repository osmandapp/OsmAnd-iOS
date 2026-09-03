//
//  PlanRouteButtonFactory.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

enum PlanRouteButtonFactory {
    private enum ButtonStyle {
        case map
        case glass
    }

    static let toolbarButtonSize: CGFloat = 48
    static let bottomButtonHeight: CGFloat = OAUtilities.isIPad() ? 48 : 44
    private static let bottomButtonHorizontalInset: CGFloat = 18
    private static let bottomButtonImagePadding: CGFloat = 8
    private static let bottomToolbarIconSideInset: CGFloat = 9
    private static let bottomToolbarTitleSideInset: CGFloat = 16
    private static let bottomToolbarImagePadding: CGFloat = 6
    private static let glassButtonDisabledAlpha: CGFloat = 0.45
    private static let glassButtonPressedAlpha: CGFloat = 0.88
    private static let glassButtonShadowOpacity: Float = 0.12
    private static let glassButtonShadowRadius: CGFloat = 10
    private static let glassButtonShadowOffset = CGSize(width: 0, height: 4)
    private static let glassButtonPressedScale: CGFloat = 0.985
    private static let glassEffectTag = 2_601

    static func iconButton(image: UIImage?, size: CGFloat = toolbarButtonSize) -> UIButton {
        iconButton(image: image, size: size, style: .map)
    }

    static func iconMapButton(image: UIImage?) -> OAHudButton {
        let size = toolbarButtonSize
        let button = OAHudButton(frame: CGRect(x: 0, y: 0, width: size, height: size))
        button.setCustomAppearanceParams(nil)
        button.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])
        return button
    }

    static func bottomToolbarIconButton(image: UIImage?, size: CGFloat = bottomButtonHeight) -> UIButton {
        iconButton(image: image, size: size, style: OAUtilities.isIPad() ? .map : .glass)
    }

    static func labeledButton(title: String, image: UIImage?, imagePlacement: NSDirectionalRectEdge = .leading, height: CGFloat = bottomButtonHeight) -> UIButton {
        let contentInsets = NSDirectionalEdgeInsets(top: 0, leading: bottomButtonHorizontalInset, bottom: 0, trailing: bottomButtonHorizontalInset)
        return labeledButton(title: title, image: image, imagePlacement: imagePlacement, height: height, style: .map, contentInsets: contentInsets, imagePadding: bottomButtonImagePadding)
    }

    static func bottomToolbarLabeledButton(title: String, image: UIImage?, imagePlacement: NSDirectionalRectEdge = .leading, height: CGFloat = bottomButtonHeight) -> UIButton {
        let isIconLeading = imagePlacement == .leading
        let contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                    leading: isIconLeading ? bottomToolbarIconSideInset : bottomToolbarTitleSideInset,
                                                    bottom: 0,
                                                    trailing: isIconLeading ? bottomToolbarTitleSideInset : bottomToolbarIconSideInset)
        return labeledButton(title: title, image: image, imagePlacement: imagePlacement, height: height, style: OAUtilities.isIPad() ? .map : .glass, contentInsets: contentInsets, imagePadding: bottomToolbarImagePadding)
    }

    static func primaryButton(title: String, height: CGFloat = toolbarButtonSize) -> OAHudButton {
        let normalColor = UIColor.buttonBgColorPrimary
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .scaledSystemFont(ofSize: 17, weight: .semibold, maximumSize: 22)
            return outgoing
        }
        configuration.background.cornerRadius = height / 2

        let button = OAHudButton()
        button.configuration = configuration
        button.layer.cornerRadius = height / 2
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentHorizontalAlignment = .center

        button.unpressedColorDay = normalColor.light
        button.unpressedColorNight = normalColor.dark
        button.pressedColorDay = normalColor.light
        button.pressedColorNight = normalColor.dark
        button.tintColorDay = .white
        button.tintColorNight = .white
        button.borderWidthDay = 0
        button.borderWidthNight = 0
        button.updateColors(forPressedState: false)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: height).isActive = true
        return button
    }

    private static func iconButton(image: UIImage?, size: CGFloat, style: ButtonStyle) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.image = image
        configuration.baseForegroundColor = .mapButtonIconColorDefault
        configuration.background.backgroundColor = style == .map ? .mapButtonBgColorDefault : .clear
        configuration.background.cornerRadius = size / 2
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])
        applyStyle(to: button, style: style, cornerRadius: size / 2)
        return button
    }

    private static func labeledButton(title: String, image: UIImage?, imagePlacement: NSDirectionalRectEdge, height: CGFloat, style: ButtonStyle, contentInsets: NSDirectionalEdgeInsets, imagePadding: CGFloat) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = image
        configuration.imagePlacement = imagePlacement
        configuration.imagePadding = imagePadding
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.contentInsets = contentInsets
        configuration.baseForegroundColor = .textColorPrimary
        configuration.background.backgroundColor = style == .map ? .mapButtonBgColorDefault : .clear
        configuration.background.cornerRadius = height / 2
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .scaledSystemFont(ofSize: 15, weight: .medium)
            return outgoing
        }
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: height).isActive = true
        applyStyle(to: button, style: style, cornerRadius: height / 2)
        return button
    }

    private static func applyStyle(to button: UIButton, style: ButtonStyle, cornerRadius: CGFloat) {
        switch style {
        case .map:
            applyPressedState(to: button)
            applyShadow(to: button)
        case .glass:
            applyGlassStyle(to: button, cornerRadius: cornerRadius)
        }
    }

    private static func applyPressedState(to button: UIButton) {
        button.configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.background.backgroundColor = button.isHighlighted ? .mapButtonBgColorTap : .mapButtonBgColorDefault
            button.configuration = updated
        }
    }

    private static func applyShadow(to button: UIButton) {
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.35
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 5
    }

    private static func applyGlassStyle(to button: UIButton, cornerRadius: CGFloat) {
        if #available(iOS 26.0, *) {
            applySystemGlass(to: button, cornerRadius: cornerRadius)
        } else {
            button.addBlurEffect(!OAAppSettings.sharedManager().isAppMapNightMode, cornerRadius: cornerRadius, padding: 0)
        }
        button.layer.cornerRadius = cornerRadius
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = Self.glassButtonShadowOpacity
        button.layer.shadowOffset = Self.glassButtonShadowOffset
        button.layer.shadowRadius = Self.glassButtonShadowRadius
        button.configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.background.backgroundColor = .clear
            updated?.baseForegroundColor = .textColorPrimary
            button.configuration = updated
            button.alpha = button.isEnabled ? 1 : Self.glassButtonDisabledAlpha
            if let glassView = button.viewWithTag(Self.glassEffectTag) {
                glassView.alpha = button.isHighlighted && button.isEnabled ? Self.glassButtonPressedAlpha : 1
            }
            button.transform = button.isHighlighted && button.isEnabled
                ? CGAffineTransform(scaleX: Self.glassButtonPressedScale, y: Self.glassButtonPressedScale)
                : .identity
        }
    }

    @available(iOS 26.0, *)
    private static func applySystemGlass(to button: UIButton, cornerRadius: CGFloat) {
        button.viewWithTag(glassEffectTag)?.removeFromSuperview()

        let shouldUseClearGlass = !ThemeManager.shared.isLightTheme()
        let isDarkAppearance = shouldUseClearGlass || OAAppSettings.sharedManager().isAppMapNightMode
        let glass = UIGlassEffect(style: shouldUseClearGlass ? .clear : .regular)
        if !shouldUseClearGlass {
            glass.tintColor = isDarkAppearance
                ? UIColor.black.withAlphaComponent(0.16)
                : UIColor.white.withAlphaComponent(0.12)
        }

        let glassView = UIVisualEffectView(effect: glass)
        glassView.tag = glassEffectTag
        glassView.isUserInteractionEnabled = false
        glassView.layer.cornerRadius = cornerRadius
        glassView.layer.masksToBounds = true
        glassView.overrideUserInterfaceStyle = isDarkAppearance ? .dark : .light
        glassView.translatesAutoresizingMaskIntoConstraints = false
        button.insertSubview(glassView, at: 0)

        NSLayoutConstraint.activate([
            glassView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            glassView.topAnchor.constraint(equalTo: button.topAnchor),
            glassView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
    }
}
