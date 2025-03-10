//
//  MapillaryContributeCard.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

final class MapillaryContributeCard: AbstractCard {
    
    @objc private func addPhotosButtonPressed() {
        OAMapillaryPlugin.installOrOpenMapillary()
    }

    override class func getCellNibId() -> String {
        MapillaryContributeCell.reuseIdentifier
    }
}
