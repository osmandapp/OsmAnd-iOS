//
//  BaseSwitchAppModeAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 10.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class BaseSwitchAppModeAction: OAQuickAction {
    
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
        switchAppMode()
    }
    
    override func getText() -> String? {
        localizedString(getQuickActionDescription())
    }
    
    class func getQuickActionType() -> QuickActionType {
        fatalError("getQuickActionType() has not been implemented")
    }
    
    func shouldChangeForward() -> Bool {
        fatalError("shouldChangeForward() has not been implemented")
    }
    
    func getQuickActionDescription() -> String {
        fatalError("getQuickActionDescription() has not been implemented")
    }

    private func switchAppMode() {
        let settings = OAAppSettings.sharedManager()
        let appMode = settings.applicationMode.get()
        let next = shouldChangeForward()
        let newSwitchProfile = settings.getSwitchedAppMode(appMode, next: next)
        
        if appMode != newSwitchProfile {
            settings.setApplicationModePref(newSwitchProfile)
        }
    }
}
