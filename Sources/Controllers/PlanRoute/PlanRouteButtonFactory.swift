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

    static func bottomToolbarIconButton(image: UIImage?, size: CGFloat = bottomButtonHeight) -> UIButton {
        iconButton(image: image, size: size, style: OAUtilities.isIPad() ? .map : .glass)
    }

    static func labeledButton(title: String, image: UIImage?, imagePlacement: NSDirectionalRectEdge = .leading, height: CGFloat = bottomButtonHeight) -> UIButton {
        labeledButton(title: title, image: image, imagePlacement: imagePlacement, height: height, style: .map)
    }

    static func bottomToolbarLabeledButton(title: String, image: UIImage?, imagePlacement: NSDirectionalRectEdge = .leading, height: CGFloat = bottomButtonHeight) -> UIButton {
        labeledButton(title: title, image: image, imagePlacement: imagePlacement, height: height, style: OAUtilities.isIPad() ? .map : .glass)
    }

    static func primaryButton(title: String, height: CGFloat = toolbarButtonSize) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = .buttonBgColorPrimary
        configuration.background.cornerRadius = height / 2
        let button = UIButton(configuration: configuration)
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

    private static func labeledButton(title: String, image: UIImage?, imagePlacement: NSDirectionalRectEdge, height: CGFloat, style: ButtonStyle) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = image
        configuration.imagePlacement = imagePlacement
        configuration.imagePadding = Self.bottomButtonImagePadding
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Self.bottomButtonHorizontalInset, bottom: 0, trailing: Self.bottomButtonHorizontalInset)
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
            button.addBlurEffect(!OAAppSettings.sharedManager().nightMode, cornerRadius: cornerRadius, padding: 0)
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

        let glass = UIGlassEffect(style: .regular)
        glass.tintColor = OAAppSettings.sharedManager().nightMode
            ? UIColor.black.withAlphaComponent(0.16)
            : UIColor.white.withAlphaComponent(0.12)

        let glassView = UIVisualEffectView(effect: glass)
        glassView.tag = glassEffectTag
        glassView.isUserInteractionEnabled = false
        glassView.layer.cornerRadius = cornerRadius
        glassView.layer.masksToBounds = true
        glassView.overrideUserInterfaceStyle = OAAppSettings.sharedManager().nightMode ? .dark : .light
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
