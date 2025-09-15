//
//  NextAppProfileAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 10.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class NextAppProfileAction: BaseSwitchAppModeAction {
    static var type: QuickActionType?
    
    override class func quickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.nextProfileActionId.rawValue, stringId: "change.profile.next", cl: NextAppProfileAction.self)
                .name(localizedString("quick_action_next_app_profile"))
                .nameAction(localizedString("shared_string_change"))
                .iconName("ic_custom_profile_next")
                .nonEditable()
                .category(QuickActionTypeCategory.settings.rawValue)
        }
        return type ?? super.type()
    }
    
    override func shouldChangeForward() -> Bool {
        true
    }
    
    override func quickActionDescription() -> String {
        "key_event_action_next_app_profile"
    }
}
