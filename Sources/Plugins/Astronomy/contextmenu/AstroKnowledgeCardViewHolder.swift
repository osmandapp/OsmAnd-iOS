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
        actionButton = UIButton(configuration: Self.makeButtonConfiguration(item: item))
        super.init()
        setup(item: item, onActionClick: onActionClick)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func makeButtonConfiguration(item: AstroKnowledgeCardItem) -> UIButton.Configuration {
        if item.state == .download {
            makeButtonConfigurationDownload(title: item.buttonTitle)
        } else {
            makeButtonConfigurationUpsell(title: item.buttonTitle)
        }
    }

    private static func makeButtonConfigurationDownload(title: String) -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = .textColorActive
        config.titleAlignment = .leading
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .monospacedFont(at: 17, withTextStyle: .body)
            return outgoing
        }
        
        return config
    }
    
    private static func makeButtonConfigurationUpsell(title: String) -> UIButton.Configuration {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = .buttonBgColorTertiary
        config.baseForegroundColor = .textColorActive
        config.background.cornerRadius = 10
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .preferredFont(forTextStyle: .body)
            return outgoing
        }
        
        return config
    }

    func update(item: AstroKnowledgeCardItem) {
        guard currentButtonTitle != item.buttonTitle || currentActionEnabled != item.actionEnabled else {
            return
        }
        currentButtonTitle = item.buttonTitle
        currentActionEnabled = item.actionEnabled
        actionButton.configuration = Self.makeButtonConfiguration(item: item)
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
            iconView.tintColor = .iconColorActive
        }
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 30).isActive = true

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 8
        
        let title = UILabel()
        title.text = item.getTitle()
        title.textColor = .textColorPrimary
        title.font = .preferredFont(forTextStyle: .body)
        title.adjustsFontForContentSizeCategory = true
        title.numberOfLines = 0
        
        let description = UILabel()
        description.text = item.getDescription()
        description.textColor = .textColorSecondary
        description.font = .preferredFont(forTextStyle: .subheadline)
        description.numberOfLines = 0
        
        textStack.addArrangedSubview(title)
        textStack.addArrangedSubview(description)
        
        row.addArrangedSubview(textStack)
        row.addArrangedSubview(iconView)
        
        stack.addArrangedSubview(row)
        stack.setCustomSpacing(20, after: row)
        
        if item.state == .download {
            let divider = UIView()
            divider.backgroundColor = .customSeparatorSolid
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            stack.addArrangedSubview(divider)
            stack.setCustomSpacing(0, after: divider)
            
            actionButton.isEnabled = item.actionEnabled
            actionButton.addAction(UIAction { _ in onActionClick() }, for: .touchUpInside)
            actionButton.contentHorizontalAlignment = .leading
            stack.addArrangedSubview(actionButton)
        } else {
            actionButton.isEnabled = item.actionEnabled
            actionButton.addAction(UIAction { _ in onActionClick() }, for: .touchUpInside)
            textStack.addArrangedSubview(actionButton)
            textStack.setCustomSpacing(21, after: description)
            row.spacing = 16
            stack.isLayoutMarginsRelativeArrangement = true
            stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)
        }
    }
}

enum AstroKnowledgeCardViewHolder {
    static func makeView(item: AstroKnowledgeCardItem, onActionClick: @escaping () -> Void) -> UIView {
        AstroKnowledgeCardView(item: item, onActionClick: onActionClick)
    }
}
