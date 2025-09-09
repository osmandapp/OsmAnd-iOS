//
//  PreviousAppProfileAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 28.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class PreviousAppProfileAction: BaseSwitchAppModeAction {
    static var type: QuickActionType?
    
    override class func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.previousProfileActionId.rawValue, stringId: "change.profile.previous", cl: PreviousAppProfileAction.self)
                .name(localizedString("quick_action_previous_app_profile"))
                .nameAction(localizedString("shared_string_change"))
                .iconName("ic_action_profile_previous")
                .nonEditable()
                .category(QuickActionTypeCategory.settings.rawValue)
        }
        return type ?? super.type()
    }
    
    override func shouldChangeForward() -> Bool {
        false
    }
    
    override func getQuickActionDescription() -> String {
        "key_event_action_previous_app_profile"
    }
    
    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_action_profile_previous")
    }
}
