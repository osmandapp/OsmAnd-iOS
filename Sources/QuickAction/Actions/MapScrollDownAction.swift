//
//  MapScrollDownAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MapScrollDownAction: BaseMapScrollAction {
    private static let type = QuickActionType(id: QuickActionIds.mapScrollDownActionId.rawValue, stringId: "map.scroll.down", cl: MapScrollDownAction.self)
        .name(localizedString("quick_action_move_map_down"))
        .nameAction(localizedString("shared_string_move"))
        .iconName("ic_custom_map_move_down")
        .nonEditable()
        .category(QuickActionTypeCategory.mapInteractions.rawValue)
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func scrollingDirection() -> EOAMapPanDirection {
        .down
    }
    
    override func quickActionDescription() -> String {
        "key_event_action_move_down"
    }
}
