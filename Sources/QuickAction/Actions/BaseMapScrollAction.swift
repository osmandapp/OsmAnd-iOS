//
//  BaseMapScrollAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class BaseMapScrollAction: OAQuickAction {
    override init() {
        super.init(actionType: Self.getType())
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
        
    override func getText() -> String? {
        localizedString(quickActionDescription())
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        MapScrollHelper.shared.startScrolling(direction: scrollingDirection())
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        MapScrollHelper.shared.stopScrolling(direction: scrollingDirection())
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        MapScrollHelper.shared.stopScrolling(direction: scrollingDirection())
    }

    override func execute() {
        MapScrollHelper.shared.performPan(for: scrollingDirection())
    }
        
    func scrollingDirection() -> EOAMapPanDirection {
        fatalError("getScrollingDirection() has not been implemented")
    }
    
    func quickActionDescription() -> String {
        fatalError("getQuickActionDescription() has not been implemented")
    }
}
