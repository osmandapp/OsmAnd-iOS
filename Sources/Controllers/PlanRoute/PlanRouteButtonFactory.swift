//
//  PlanRouteButtonFactory.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

enum PlanRouteButtonFactory {
    static let toolbarButtonSize: CGFloat = 48
    static let bottomButtonHeight: CGFloat = OAUtilities.isIPad() ? 48 : 44

    static func iconButton(image: UIImage?, size: CGFloat = toolbarButtonSize) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.image = image
        configuration.baseForegroundColor = .mapButtonIconColorDefault
        configuration.background.backgroundColor = .mapButtonBgColorDefault
        configuration.background.cornerRadius = size / 2
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])
        applyPressedState(to: button)
        applyShadow(to: button)
        return button
    }

    static func labeledButton(title: String, image: UIImage?, imagePlacement: NSDirectionalRectEdge = .leading, height: CGFloat = bottomButtonHeight) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = image
        configuration.imagePlacement = imagePlacement
        configuration.imagePadding = 6
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)
        configuration.baseForegroundColor = .textColorPrimary
        configuration.background.backgroundColor = .mapButtonBgColorDefault
        configuration.background.cornerRadius = height / 2
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: height).isActive = true
        applyPressedState(to: button)
        applyShadow(to: button)
        return button
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
}
