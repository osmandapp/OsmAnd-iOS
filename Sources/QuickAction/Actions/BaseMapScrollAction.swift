//
//  BaseMapScrollAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class BaseMapScrollAction: OAQuickAction {
    override init() {
        super.init(actionType: Self.quickActionType())
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func execute() {
        let mapViewController = OARootViewController.instance().mapPanel.mapViewController
        switch scrollingDirection() {
        case .up:
            mapViewController.animatedPanUp()
        case .down:
            mapViewController.animatedPanDown()
        case .left:
            mapViewController.animatedPanLeft()
        case .right:
            mapViewController.animatedPanRight()
        @unknown default:
            return
        }
    }
    
    override func getText() -> String? {
        localizedString(quickActionDescription())
    }
    
    class func quickActionType() -> QuickActionType {
        fatalError("getQuickActionType() has not been implemented")
    }
    
    func scrollingDirection() -> EOAMapPanDirection {
        fatalError("getScrollingDirection() has not been implemented")
    }
    
    func quickActionDescription() -> String {
        fatalError("getQuickActionDescription() has not been implemented")
    }
}
