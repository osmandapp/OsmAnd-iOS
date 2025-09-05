//
//  MapSettingsButtonState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MapSettingsButtonState: MapButtonState {
    static let hudId = "map.view.layers"
    
    init() {
        super.init(withId: Self.hudId)
    }
    
    override func getName() -> String {
        localizedString("configure_map")
    }
    
    @discardableResult override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.companion.POS_LEFT, posV: ButtonPositionSize.companion.POS_TOP, xMove: false, yMove: true)
    }
}
