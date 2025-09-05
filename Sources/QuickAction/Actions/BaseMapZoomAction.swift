//
//  BaseMapZoomAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 28.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class BaseMapZoomAction: OAQuickAction {
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
        shouldIncrement() ? OARootViewController.instance().zoomIn() : OARootViewController.instance().zoomOut()
    }
    
    override func getText() -> String? {
        localizedString(getQuickActionDescription())
    }
    
    class func getQuickActionType() -> QuickActionType {
        fatalError()
    }
    
    func shouldIncrement() -> Bool {
        fatalError()
    }
    
    func getQuickActionDescription() -> String {
        fatalError()
    }
}
