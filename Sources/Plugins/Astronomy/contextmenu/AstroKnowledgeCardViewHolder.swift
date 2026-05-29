//
//  AstroKnowledgeCardViewHolder.swift
//  OsmAnd Maps
//
//  Ported from Android AstroKnowledgeCardViewHolder.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

enum AstroKnowledgeCardViewHolder {
    static func makeView(item: AstroKnowledgeCardItem, onActionClick: @escaping () -> Void) -> UIView {
        let card = AstroCardContainerView()
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12

        let iconView = UIImageView(image: UIImage(systemName: item.getIconName()))
        iconView.tintColor = AstroContextMenuTheme.activeIcon
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
        card.stack.addArrangedSubview(row)

        var config = UIButton.Configuration.filled()
        config.title = item.buttonTitle
        config.baseBackgroundColor = AstroContextMenuTheme.primaryButton
        config.baseForegroundColor = .white
        let button = UIButton(configuration: config)
        button.isEnabled = item.actionEnabled
        button.addAction(UIAction { _ in onActionClick() }, for: .touchUpInside)
        card.stack.addArrangedSubview(button)
        return card
    }
}
