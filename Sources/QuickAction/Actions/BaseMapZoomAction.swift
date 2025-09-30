//
//  BaseMapZoomAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class BaseMapZoomAction: OAQuickAction {
    override init() {
        super.init(actionType: Self.getType())
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func execute() {
        shouldIncrement() ? OARootViewController.instance().mapPanel.mapViewController.zoomIn() : OARootViewController.instance().mapPanel.mapViewController.zoomOut()
    }
    
    override func getText() -> String? {
        localizedString(quickActionDescription())
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        actionSelected()
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        // Reject base method execution
    }
        
    func shouldIncrement() -> Bool {
        fatalError("shouldIncrement() has not been implemented")
    }
    
    func quickActionDescription() -> String {
        fatalError("getQuickActionDescription() has not been implemented")
    }
}
