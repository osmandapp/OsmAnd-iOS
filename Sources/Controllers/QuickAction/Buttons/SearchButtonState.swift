//
//  SearchButtonState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class SearchButtonState: MapButtonState {
    static let hudId = "map.view.quick_search"
    
    init() {
        super.init(withId: Self.hudId)
    }
    
    override func getName() -> String {
        localizedString("shared_string_search")
    }
    
    @discardableResult override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.companion.POS_LEFT, posV: ButtonPositionSize.companion.POS_TOP, xMove: true, yMove: false)
    }
}
