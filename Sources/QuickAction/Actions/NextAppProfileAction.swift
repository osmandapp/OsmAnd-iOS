//
//  NextAppProfileAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 10.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class NextAppProfileAction: BaseSwitchAppModeAction {
    private static let type = QuickActionType(id: QuickActionIds.nextProfileActionId.rawValue, stringId: "change.profile.next", cl: NextAppProfileAction.self)
        .name(localizedString("quick_action_next_app_profile"))
        .nameAction(localizedString("shared_string_change"))
        .iconName("ic_custom_profile_next")
        .nonEditable()
        .category(QuickActionTypeCategory.settings.rawValue)
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func shouldChangeForward() -> Bool {
        true
    }
    
    override func quickActionDescription() -> String {
        "key_event_action_next_app_profile"
    }
}
