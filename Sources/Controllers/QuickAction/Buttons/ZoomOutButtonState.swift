//
//  ZoomOutButtonState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ZoomOutButtonState: MapButtonState {
    static let hudId = "map.view.zoom_out"
    
    init() {
        super.init(withId: Self.hudId)
    }
    
    override func getName() -> String {
        localizedString("key_hint_zoom_out")
    }
    
    @discardableResult override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.companion.POS_RIGHT, posV: ButtonPositionSize.companion.POS_BOTTOM, xMove: false, yMove: true)
    }
}
