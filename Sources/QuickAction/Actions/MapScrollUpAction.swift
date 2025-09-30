//
//  MapScrollUpAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MapScrollUpAction: BaseMapScrollAction {
    private static let type = QuickActionType(id: QuickActionIds.mapScrollUpActionId.rawValue, stringId: "map.scroll.up", cl: MapScrollUpAction.self)
        .name(localizedString("quick_action_move_map_up"))
        .nameAction(localizedString("shared_string_move"))
        .iconName("ic_custom_map_move_up")
        .nonEditable()
        .category(QuickActionTypeCategory.mapInteractions.rawValue)
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func scrollingDirection() -> EOAMapPanDirection {
        .up
    }
    
    override func quickActionDescription() -> String {
        "key_event_action_move_up"
    }
}
