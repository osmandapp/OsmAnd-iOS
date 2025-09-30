//
//  PreviousAppProfileAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 10.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class PreviousAppProfileAction: BaseSwitchAppModeAction {
    private static let type = QuickActionType(id: QuickActionIds.previousProfileActionId.rawValue, stringId: "change.profile.previous", cl: PreviousAppProfileAction.self)
        .name(localizedString("quick_action_previous_app_profile"))
        .nameAction(localizedString("shared_string_change"))
        .iconName("ic_custom_profile_previous")
        .nonEditable()
        .category(QuickActionTypeCategory.settings.rawValue)
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func shouldChangeForward() -> Bool {
        false
    }
    
    override func quickActionDescription() -> String {
        "key_event_action_previous_app_profile"
    }
}
