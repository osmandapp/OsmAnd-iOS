//
//  DisplayPositionAction.swift
//  OsmAnd Maps
//
//  Created by Skalii on 10.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class DisplayPositionAction: OAQuickAction {

    static let type = QuickActionType(id: QuickActionIds.displayPositionActionId.rawValue,
                                      stringId: "display.position.switch",
                                      cl: DisplayPositionAction.self)
        .name(localizedString("position_on_map"))
        .nameAction(localizedString("shared_string_change"))
        .iconName("ic_custom_display_position_center")
        .secondaryIconName("ic_custom_compound_action_change")
        .category(QuickActionTypeCategory.settings.rawValue)
        .nonEditable()

    private let settings = OAAppSettings.sharedManager()!

    override init() {
        super.init(actionType: Self.type)
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }

    override func getName() -> String {
        localizedString("position_on_map")
    }

    override func getIconResName() -> String {
        switch settings.positionPlacementOnMap.get() {
        case 0: "ic_custom_display_position_center"
        case 1: "ic_custom_display_position_bottom"
        default: "ic_custom_display_position_automatic"
        }
    }

    override func getStateName() -> String {
        String(format: localizedString("ltr_or_rtl_combine_via_dash"), localizedString("shared_string_change"), getName())
    }

    override func getText() -> String {
        localizedString("quick_action_toggle_preference")
    }

    override func execute() {
        let currentState = settings.positionPlacementOnMap.get()
        settings.positionPlacementOnMap.set((currentState == 2) ? 0 : currentState + 1)
    }
}
