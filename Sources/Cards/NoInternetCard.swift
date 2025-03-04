//
//  NoInternetCard.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 28.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class NoInternetCard: AbstractCard {
    var onTryAgainAction: (() -> Void)?
    
    override class func getCellNibId() -> String {
        NoInternetCardCell.reuseIdentifier
    }
}
