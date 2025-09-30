//
//  MapScrollLeftAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MapScrollLeftAction: BaseMapScrollAction {
    private static let type = QuickActionType(id: QuickActionIds.mapScrollLeftActionId.rawValue, stringId: "map.scroll.left", cl: MapScrollLeftAction.self)
        .name(localizedString("quick_action_move_map_left"))
        .nameAction(localizedString("shared_string_move"))
        .iconName("ic_custom_map_move_left")
        .nonEditable()
        .category(QuickActionTypeCategory.mapInteractions.rawValue)
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func scrollingDirection() -> EOAMapPanDirection {
        .left
    }
    
    override func quickActionDescription() -> String {
        "key_event_action_move_left"
    }
}
