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
            description.text = item.description
            description.textColor = AstroContextMenuTheme.primaryText
            description.font = .systemFont(ofSize: 18)
            description.numberOfLines = 8
            card.stack.addArrangedSubview(description)
        }

        if item.linkType != nil && (item.readMoreUri != nil || item.hasOfflineArticle) {
            var config = UIButton.Configuration.plain()
            config.image = AstroIcon.template(item.linkType == .wikidata ? "ic_action_logo_wikidata" : "ic_plugin_wikipedia")
            config.imagePadding = 8
            config.baseForegroundColor = AstroContextMenuTheme.activeText
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
            if item.hasOfflineArticle && item.linkType == .wikipedia {
                config.title = localizedString("context_menu_read_full_article")
            } else {
                let targetName = item.linkType == .wikidata
                    ? localizedString("wikidata")
                    : localizedString("shared_string_wikipedia")
                let readOn = localizedString("read_on")
                config.title = readOn.contains("%@") ? String(format: readOn, targetName) : "\(readOn) \(targetName)"
            }
            let button = UIButton(configuration: config)
            button.contentHorizontalAlignment = .leading
            button.addAction(UIAction { _ in onReadClick(item) }, for: .touchUpInside)
            card.stack.addArrangedSubview(button)
        }
        return card
    }
}
