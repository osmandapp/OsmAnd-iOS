//
//  BaseSwitchAppModeAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class BaseSwitchAppModeAction: OAQuickAction {
    private let changeProfileDelay: Double = 3500
    private var delayedSwitchProfile: OAApplicationMode?
    
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
        
        if delayedSwitchProfile == nil {
            delayedSwitchProfile = appMode
        }
        let patternDelayedSwitch = localizedString("selected_delayed_profile")
        if let delayedSwitchProfile {
            self.delayedSwitchProfile = settings.getSwitchedAppMode(delayedSwitchProfile, next: next)
            let messageDelayedSwitch = String(format: patternDelayedSwitch, delayedSwitchProfile.toHumanString())
            OAUtilities.showToast(messageDelayedSwitch, details: nil, duration: 4, in: OARootViewController.instance().view)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + changeProfileDelay) {
            if let delayedSwitchProfile = self.delayedSwitchProfile, appMode != delayedSwitchProfile {
                settings.setApplicationModePref(delayedSwitchProfile)
                let pattern = localizedString("application_profile_changed")
                let message = String(format: pattern, delayedSwitchProfile.toHumanString())
                OAUtilities.showToast(message, details: nil, duration: 4, in: OARootViewController.instance().view)
            }
            self.delayedSwitchProfile = nil
        }
    }
}
