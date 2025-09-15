//
//  MapZoomOutAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MapZoomOutAction: BaseMapZoomAction {
    static var type: QuickActionType?
    
    override class func quickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.mapZoomOutActionId.rawValue, stringId: "map.zoom.out", cl: MapZoomOutAction.self)
                .name(localizedString("key_event_action_zoom_out"))
                .nameAction(localizedString("shared_string_map"))
                .iconName("ic_custom_magnifier_minus")
                .nonEditable()
                .category(QuickActionTypeCategory.mapInteractions.rawValue)
        }
        return type ?? super.type()
    }
    
    override func shouldIncrement() -> Bool {
        false
    }
    
    override func quickActionDescription() -> String {
        "key_event_action_zoom_out"
    }
}
