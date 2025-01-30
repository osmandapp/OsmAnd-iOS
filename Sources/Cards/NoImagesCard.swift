//
//  NoImagesCard.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class CardFilter: NSObject {
    static func getAvailableContentForOnlinePhotosSection(_ cards: [AbstractCard]) -> [AbstractCard] {
        cards.onlinePhotosSection
    }
    
    static func getAvailableContentForMapillaryPhotosSection(_ cards: [AbstractCard]) -> [AbstractCard] {
        cards.mapillaryPhotosSection
    }
}

extension Array where Element: AbstractCard {
    var onlinePhotosSection: [AbstractCard] {
        filter { !($0 is MapillaryContributeCard || $0 is MapillaryImageCard) }
    }
    
    var mapillaryPhotosSection: [AbstractCard] {
        filter { !($0 is WikiImageCard || $0 is UrlImageCard || $0 is ImageCard) }
    }
    
    var hasOnlyOnlinePhotosContent: Bool {
        !filter { ($0 is WikiImageCard || $0 is UrlImageCard || $0 is ImageCard) }.isEmpty
    }
    
    var hasOnlyMapillaryPhotosContent: Bool {
        !filter { ($0 is MapillaryContributeCard || $0 is MapillaryImageCard) }.isEmpty
    }
}

@objcMembers
final class NoImagesCard: AbstractCard {
    
    override class func getCellNibId() -> String {
        NoImagesCell.reuseIdentifier
    }
}
