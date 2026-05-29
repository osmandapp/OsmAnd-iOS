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
        let card = AstroCardContainerView(title: AstroContextMenuLocalizer.label("shared_string_description", fallback: "Description"),
                                          systemImageName: "doc.text")

        if !item.description.isEmpty {
            let description = UILabel()
            description.text = item.description
            description.textColor = UIColor(white: 0.86, alpha: 1)
            description.font = .systemFont(ofSize: 14)
            description.numberOfLines = 8
            card.stack.addArrangedSubview(description)
        }

        if item.linkType != nil && (item.readMoreUri != nil || item.hasOfflineArticle) {
            var config = UIButton.Configuration.plain()
            config.image = UIImage(systemName: item.linkType == .wikidata ? "link" : "globe")
            config.imagePadding = 8
            config.baseForegroundColor = .systemBlue
            if item.hasOfflineArticle && item.linkType == .wikipedia {
                config.title = AstroContextMenuLocalizer.label("context_menu_read_full_article", fallback: "Read full article")
            } else {
                let targetName = item.linkType == .wikidata
                    ? AstroContextMenuLocalizer.label("wikidata", fallback: "Wikidata")
                    : AstroContextMenuLocalizer.label("shared_string_wikipedia", fallback: "Wikipedia")
                let readOn = AstroContextMenuLocalizer.label("read_on", fallback: "Read on %@")
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

