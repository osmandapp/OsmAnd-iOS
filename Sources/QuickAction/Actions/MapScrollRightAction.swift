//
//  MapScrollRightAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MapScrollRightAction: BaseMapScrollAction {
    private static let type = QuickActionType(id: QuickActionIds.mapScrollRightActionId.rawValue, stringId: "map.scroll.right", cl: MapScrollRightAction.self)
        .name(localizedString("quick_action_move_map_right"))
        .nameAction(localizedString("shared_string_move"))
        .iconName("ic_custom_map_move_right")
        .nonEditable()
        .category(QuickActionTypeCategory.mapInteractions.rawValue)
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func scrollingDirection() -> EOAMapPanDirection {
        .right
    }
    
    override func quickActionDescription() -> String {
        "key_event_action_move_right"
    }
}
