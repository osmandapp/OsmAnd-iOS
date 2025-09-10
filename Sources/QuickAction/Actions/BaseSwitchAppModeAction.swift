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
        delayedSwitchAppMode()
    }
    
    override func getText() -> String? {
        localizedString(getQuickActionDescription())
    }
    
    class func getQuickActionType() -> QuickActionType {
        fatalError()
    }
    
    func shouldChangeForward() -> Bool {
        fatalError()
    }
    
    func getQuickActionDescription() -> String {
        fatalError()
    }

    func delayedSwitchAppMode() {
        let settings = OAAppSettings.sharedManager()
        let appMode = settings.applicationMode.get()
        let next = shouldChangeForward()
        let newSwitchProfile = settings.getSwitchedAppMode(appMode, next: next)
        
        if appMode != newSwitchProfile {
            settings.setApplicationModePref(newSwitchProfile)
        }
    }
}
