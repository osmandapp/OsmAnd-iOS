//
//  MapScrollDownAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 28.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class MapScrollDownAction: BaseMapScrollAction {
    static var type: QuickActionType?
    
    override class func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.mapScrollDownActionId.rawValue, stringId: "map.scroll.down", cl: MapScrollDownAction.self)
                .name(localizedString("quick_action_move_map_down"))
                .nameAction(localizedString("shared_string_move"))
                .iconName("ic_action_map_move_down")
                .nonEditable()
                .category(QuickActionTypeCategory.mapInteractions.rawValue)
        }
        return type ?? super.type()
    }
    
    override func getScrollingDirection() -> EOAMapPanDirection {
        EOAMapPanDirection.down
    }
    
    override func getQuickActionDescription() -> String {
        "key_event_action_move_down"
    }
    
    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_action_map_move_down")
    }
}
