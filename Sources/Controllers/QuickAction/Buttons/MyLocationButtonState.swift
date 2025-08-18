//
//  MyLocationButtonState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class MyLocationButtonState: MapButtonState {
    private static let hudId = "map.view.back_to_loc"
    
    init() {
        super.init(withId: Self.hudId)
    }
    
    override func getName() -> String {
        localizedString("shared_string_my_location")
    }
    
    @discardableResult override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.Companion().POS_RIGHT, posV: ButtonPositionSize.Companion().POS_BOTTOM, xMove: true, yMove: false)
    }
}
