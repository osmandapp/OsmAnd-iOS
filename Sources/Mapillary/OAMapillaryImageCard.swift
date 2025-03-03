//
//  MapillaryImageCard.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class MapillaryImageCard: ImageCard {
    
    private var is360: Bool
    
    override init(data: [String: Any]) {
        self.is360 = data["is360"] as? Bool ?? false
        super.init(data: data)
    }
    
    override func onCardPressed(_ mapPanel: OAMapPanelViewController) {
        OAMapillaryImageCardWrapper.onCardPressed(mapPanel, latitude: latitude, longitude: longitude, ca: ca, key: key)
    }
}
