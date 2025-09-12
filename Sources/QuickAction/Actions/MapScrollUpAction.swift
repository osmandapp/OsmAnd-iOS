//
//  MapScrollUpAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MapScrollUpAction: BaseMapScrollAction {
    static var type: QuickActionType?
    
    override class func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.mapScrollUpActionId.rawValue, stringId: "map.scroll.up", cl: MapScrollUpAction.self)
                .name(localizedString("quick_action_move_map_up"))
                .nameAction(localizedString("shared_string_move"))
                .iconName("ic_custom_map_move_up")
                .nonEditable()
                .category(QuickActionTypeCategory.mapInteractions.rawValue)
        }
        return type ?? super.type()
    }
    
    override func getScrollingDirection() -> EOAMapPanDirection {
        .up
    }
    
    override func getQuickActionDescription() -> String {
        "key_event_action_move_up"
    }
}
