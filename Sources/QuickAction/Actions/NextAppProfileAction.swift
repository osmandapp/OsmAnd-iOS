//
//  NextAppProfileAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class NextAppProfileAction: BaseSwitchAppModeAction {
    static var type: QuickActionType?
    
    override class func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.nextProfileActionId.rawValue, stringId: "change.profile.next", cl: NextAppProfileAction.self)
                .name(localizedString("quick_action_next_app_profile"))
                .nameAction(localizedString("shared_string_change"))
                .iconName("ic_action_profile_next")
                .nonEditable()
                .category(QuickActionTypeCategory.settings.rawValue)
        }
        return type ?? super.type()
    }
    
    override func shouldChangeForward() -> Bool {
        true
    }
    
    override func getQuickActionDescription() -> String {
        "key_event_action_next_app_profile"
    }
    
    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_action_profile_next")
    }
}
