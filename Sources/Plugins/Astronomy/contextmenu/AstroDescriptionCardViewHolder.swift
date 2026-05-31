//
//  AstroDescriptionCardViewHolder.swift
//  OsmAnd Maps
//
//  Ported from Android AstroDescriptionCardViewHolder.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

enum AstroDescriptionCardViewHolder {
    static func makeView(item: AstroDescriptionCardItem,
                         onReadClick: @escaping (AstroDescriptionCardItem) -> Void) -> UIView {
        let card = AstroCardContainerView()

        if !item.description.isEmpty {
            let description = UILabel()
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            paragraphStyle.lineBreakMode = .byTruncatingTail
            description.attributedText = NSAttributedString(
                string: item.description,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: AstroContextMenuTheme.primaryText,
                    .paragraphStyle: paragraphStyle
                ])
            description.textColor = AstroContextMenuTheme.primaryText
            description.font = .systemFont(ofSize: 16)
            description.numberOfLines = 3
            description.lineBreakMode = .byTruncatingTail
            card.stack.addArrangedSubview(description)
        }

        if let linkType = item.linkType, item.readMoreUri != nil || item.hasOfflineArticle {
            var config = UIButton.Configuration.plain()
            config.image = AstroIcon.template(linkType == .wikidata ? "ic_action_logo_wikidata" : "ic_plugin_wikipedia")
            config.imagePadding = 10
            config.imageColorTransformer = UIConfigurationColorTransformer { _ in
                AstroContextMenuTheme.defaultIcon
            }
            config.baseForegroundColor = AstroContextMenuTheme.secondaryText
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)
            config.background.backgroundColor = .clear
            config.background.cornerRadius = 6
            config.background.strokeColor = AstroContextMenuTheme.separator
            config.background.strokeWidth = 1

            let opensOfflineArticle = item.hasOfflineArticle && linkType == .wikipedia
            let text: String
            let activeText: String
            if opensOfflineArticle {
                text = localizedString("context_menu_read_full_article")
                activeText = text
            } else {
                let targetName = linkType == .wikidata
                    ? localizedString("wikidata")
                    : localizedString("shared_string_wikipedia")
                let readOn = localizedString("read_on")
                text = readOn.contains("%@") ? String(format: readOn, targetName) : "\(readOn) \(targetName)"
                activeText = targetName
            }

            var attributedTitle = AttributedString(text)
            attributedTitle.font = .systemFont(ofSize: 16)
            attributedTitle.foregroundColor = AstroContextMenuTheme.secondaryText
            if let range = attributedTitle.range(of: activeText) {
                attributedTitle[range].foregroundColor = AstroContextMenuTheme.activeText
            }
            config.attributedTitle = attributedTitle

            let button = UIButton(configuration: config)
            button.contentHorizontalAlignment = .leading
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
            button.addAction(UIAction { _ in onReadClick(item) }, for: .touchUpInside)
            card.stack.addArrangedSubview(button)
        }
        return card
    }
}
