//
//  AstroKnowledgeCardViewHolder.swift
//  OsmAnd Maps
//
//  Ported from Android AstroKnowledgeCardViewHolder.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class AstroKnowledgeCardView: AstroCardContainerView {
    private let actionButton: UIButton
    private var currentButtonTitle: String
    private var currentActionEnabled: Bool

    init(item: AstroKnowledgeCardItem, onActionClick: @escaping () -> Void) {
        currentButtonTitle = item.buttonTitle
        currentActionEnabled = item.actionEnabled
        actionButton = UIButton(configuration: Self.makeButtonConfiguration(title: item.buttonTitle))
        super.init()
        setup(item: item, onActionClick: onActionClick)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(item: AstroKnowledgeCardItem) {
        guard currentButtonTitle != item.buttonTitle || currentActionEnabled != item.actionEnabled else {
            return
        }
        currentButtonTitle = item.buttonTitle
        currentActionEnabled = item.actionEnabled
        actionButton.configuration = Self.makeButtonConfiguration(title: item.buttonTitle)
        actionButton.isEnabled = item.actionEnabled
    }

    private func setup(item: AstroKnowledgeCardItem, onActionClick: @escaping () -> Void) {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12

        let iconName = item.getIconName()
        let iconView = UIImageView(image: AstroIcon.original(iconName) ?? AstroIcon.template(iconName))
        if iconName != "ic_custom_telescope_colored" && iconName != "ic_custom_sky_map_download" {
            iconView.tintColor = AstroContextMenuTheme.activeIcon
        }
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 34).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 34).isActive = true
        row.addArrangedSubview(iconView)

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 5
        let title = UILabel()
        title.text = item.getTitle()
        title.textColor = AstroContextMenuTheme.primaryText
        title.font = .systemFont(ofSize: 17, weight: .semibold)
        title.numberOfLines = 0
        let description = UILabel()
        description.text = item.getDescription()
        description.textColor = AstroContextMenuTheme.secondaryText
        description.font = .systemFont(ofSize: 14)
        description.numberOfLines = 0
        textStack.addArrangedSubview(title)
        textStack.addArrangedSubview(description)
        row.addArrangedSubview(textStack)
        stack.addArrangedSubview(row)

        actionButton.isEnabled = item.actionEnabled
        actionButton.addAction(UIAction { _ in onActionClick() }, for: .touchUpInside)
        stack.addArrangedSubview(actionButton)
    }

    private static func makeButtonConfiguration(title: String) -> UIButton.Configuration {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = AstroContextMenuTheme.primaryButton
        config.baseForegroundColor = .white
        return config
    }
}

enum AstroKnowledgeCardViewHolder {
    static func makeView(item: AstroKnowledgeCardItem, onActionClick: @escaping () -> Void) -> UIView {
        AstroKnowledgeCardView(item: item, onActionClick: onActionClick)
    }
}
