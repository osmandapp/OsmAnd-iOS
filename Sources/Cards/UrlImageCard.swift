//
//  UrlImageCard.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class UrlImageCard: ImageCard {
    
    override func onCardPressed(_ mapPanel: OAMapPanelViewController) {
        let cardUrl = getSuitableUrl()
        if let viewController = OAWebViewController(urlAndTitle: cardUrl,
                                                    title: mapPanel.getCurrentTargetPoint()?.title) {
            mapPanel.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
