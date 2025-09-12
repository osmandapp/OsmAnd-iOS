//
//  MapZoomInAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MapZoomInAction: BaseMapZoomAction {
    static var type: QuickActionType?
    
    override class func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.mapZoomInActionId.rawValue, stringId: "map.zoom.in", cl: MapZoomInAction.self)
                .name(localizedString("key_event_action_zoom_in"))
                .nameAction(localizedString("shared_string_map"))
                .iconName("ic_custom_magnifier")
                .nonEditable()
                .category(QuickActionTypeCategory.mapInteractions.rawValue)
        }
        return type ?? super.type()
    }
    
    override func shouldIncrement() -> Bool {
        true
    }
    
    override func getQuickActionDescription() -> String {
        "key_event_action_zoom_in"
    }
}
