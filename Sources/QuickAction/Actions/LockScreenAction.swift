//
//  LockScreenAction.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 07.11.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class LockScreenAction: OAQuickAction {
    static let type = QuickActionType(id: QuickActionIds.lockScreenAction.rawValue,
                                      stringId: "lock_screen_action",
                                      cl: LockScreenAction.self)
        .name(localizedString("lock_screen"))
        .nameAction(localizedString("quick_action_verb_turn_on_off"))
        .iconName("ic_custom_touch_screen_lock")
        .category(QuickActionTypeCategory.interface.rawValue)
    
    override init() {
        super.init(actionType: Self.type)
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func getIconResName() -> String {
        LockHelper.shared.isScreenLocked ? "ic_custom_lock_open" : "ic_custom_lock_closed"
    }
    
    override func getText() -> String {
        localizedString("lock_screen_description")
    }
    
    override func execute() {
        if let buttonsController = OARootViewController.instance().mapPanel.hudViewController?.floatingButtonsController, buttonsController.isActionSheetVisible() {
            buttonsController.hideActionsSheetAnimated()
        }
        LockHelper.shared.toggleLockScreen()
        showToast()
    }
    
    func showToast() {
        let toastString = LockHelper.shared.isScreenLocked ? "screen_is_locked_by_action_button" : "screen_is_unlocked"
        OAUtilities.showToast(localizedString(toastString), details: nil, duration: 4, in: OARootViewController.instance().view)
    }
}
