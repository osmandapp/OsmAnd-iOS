//
//  CardsFilter.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 31.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class CardsFilter {
    private var cards: [AbstractCard]
    
    lazy var onlinePhotosSection: [AbstractCard] = {
        cards.filter { !($0 is MapillaryContributeCard || $0 is MapillaryImageCard) }
    }()
    
    lazy var mapillaryPhotosSection: [AbstractCard] = {
        cards.filter { !(type(of: $0) == ImageCard.self || $0 is WikiImageCard || $0 is UrlImageCard) }
    }()
    
    lazy var mapillaryImageCards: [MapillaryImageCard] = {
        cards.compactMap { $0 as? MapillaryImageCard }
    }()
    
    lazy var hasMapillaryBanner: Bool = {
        cards.contains { $0 is MapillaryContributeCard }
    }()
    
    lazy var noInternetCard: NoInternetCard? = {
        cards.compactMap { $0 as? NoInternetCard }.first
    }()
    
    lazy var cardsIsEmpty: Bool = {
        cards.isEmpty
    }()
    
    lazy var hasOnlyOnlinePhotosContent: Bool = {
        cards.contains { $0 is WikiImageCard || $0 is UrlImageCard || type(of: $0) == ImageCard.self }
    }()
    
    lazy var hasOnlyMapillaryPhotosContent: Bool = {
        cards.contains { ($0 is MapillaryContributeCard || $0 is MapillaryImageCard) }
    }()
    
    // MARK: - Init
    init(cards: [AbstractCard]) {
        self.cards = cards
    }
}
