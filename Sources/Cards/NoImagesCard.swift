//
//  NoImagesCard.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class NoImagesCard: AbstractCard {
    
    override class func getCellNibId() -> String {
        NoImagesCell.reuseIdentifier
    }
}
