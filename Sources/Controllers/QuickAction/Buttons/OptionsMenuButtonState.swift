//
//  OptionsMenuButtonState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class OptionsMenuButtonState: MapButtonState {
    static let hudId = "map.view.menu"
    
    init() {
        super.init(withId: Self.hudId)
    }
    
    override func getName() -> String {
        localizedString("shared_string_menu")
    }
    
    @discardableResult override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.Companion().POS_LEFT, posV: ButtonPositionSize.Companion().POS_BOTTOM, xMove: true, yMove: false)
    }
}
