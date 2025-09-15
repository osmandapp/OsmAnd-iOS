//
//  BaseMapScrollAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class BaseMapScrollAction: OAQuickAction {
    override init() {
        super.init(actionType: Self.getQuickActionType())
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func execute() {
        let mapViewController = OARootViewController.instance().mapPanel.mapViewController
        switch getScrollingDirection() {
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
        localizedString(getQuickActionDescription())
    }
    
    class func getQuickActionType() -> QuickActionType {
        fatalError("getQuickActionType() has not been implemented")
    }
    
    func getScrollingDirection() -> EOAMapPanDirection {
        fatalError("getScrollingDirection() has not been implemented")
    }
    
    func getQuickActionDescription() -> String {
        fatalError("getQuickActionDescription() has not been implemented")
    }
}
