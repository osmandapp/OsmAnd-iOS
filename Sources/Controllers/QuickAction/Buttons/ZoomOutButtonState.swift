//
//  ZoomOutButtonState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ZoomOutButtonState: MapButtonState {
    private static let hudId = "map.view.zoom_out"
    
    init() {
        super.init(withId: Self.hudId)
    }
    
    override func getName() -> String {
        localizedString("key_hint_zoom_out")
    }
    
    @discardableResult override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.Companion().POS_RIGHT, posV: ButtonPositionSize.Companion().POS_BOTTOM, xMove: false, yMove: true)
    }
}
