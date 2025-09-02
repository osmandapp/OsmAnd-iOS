//
//  DriveModeButtonState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class DriveModeButtonState: MapButtonState {
    static let hudId = "map.view.route_planning"
    
    init() {
        super.init(withId: Self.hudId)
    }
    
    override func getName() -> String {
        localizedString("shared_string_navigation")
    }
    
    @discardableResult override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.companion.POS_LEFT, posV: ButtonPositionSize.companion.POS_BOTTOM, xMove: true, yMove: false)
    }
}
