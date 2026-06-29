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

        let card = WikipediaContextMenuView()
        card.backgroundColor = .groupBg
        card.layer.cornerRadius = 26
        card.layer.masksToBounds = true
        
        let showButton = item.linkType != nil && (item.readMoreUri != nil || item.hasOfflineArticle)
        let buttonText: String
        var icon: UIImage? = .templateImageNamed("ic_custom_wikipedia")
        
        if showButton, let linkType = item.linkType {
            buttonText = makeReadButtonText(linkType: linkType, hasOfflineArticle: item.hasOfflineArticle)
            icon = linkType == .wikidata ? .init(named: "ic_custom_logo_wikidata") : .templateImageNamed("ic_custom_wikipedia")?.withTintColor(.iconColorDefault)
        } else {
            buttonText = ""
            icon = nil
        }
        card.configure(
            text: item.description,
            buttonText: buttonText,
            icon: icon,
            onButtonAction: showButton ? { onReadClick(item) } : {}
        )
        
        return card
    }
    
    private static func makeReadButtonText(linkType: AstroDescriptionLinkType, hasOfflineArticle: Bool) -> String {
        let opensOfflineArticle = hasOfflineArticle && linkType == .wikipedia
        
        if opensOfflineArticle {
            return localizedString("context_menu_read_full_article")
        }
        
        let targetName = linkType == .wikidata
            ? localizedString("wikidata")
            : localizedString("shared_string_wikipedia")
        
        let readOn = localizedString("read_on")
        
        return readOn.contains("%@") ? String(format: readOn, targetName) : "\(readOn) \(targetName)"
    }
}
