//
//  BaseMapScrollAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 28.08.2025.
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
        let rootViewController = OARootViewController.instance()
        switch getScrollingDirection() {
        case .up:
            rootViewController?.panUp()
        case .down:
            rootViewController?.panDown()
        case .left:
            rootViewController?.panLeft()
        case .right:
            rootViewController?.panRight()
        @unknown default:
            return
        }
    }
    
    override func getText() -> String? {
        localizedString(getQuickActionDescription())
    }
    
    class func getQuickActionType() -> QuickActionType {
        fatalError()
    }
    
    func getScrollingDirection() -> EOAMapPanDirection {
        fatalError()
    }
    
    func getQuickActionDescription() -> String {
        fatalError()
    }
}
