//
//  MapZoomOutAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 28.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class MapZoomOutAction: BaseMapZoomAction {
    static var type: QuickActionType?
    
    override class func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.mapZoomInActionId.rawValue, stringId: "map.zoom.out", cl: MapZoomOutAction.self)
                .name(localizedString("key_event_action_zoom_out"))
                .nameAction(localizedString("shared_string_map"))
                .iconName("ic_action_magnifier_minus")
                .nonEditable()
                .category(QuickActionTypeCategory.mapInteractions.rawValue)
        }
        return type ?? super.type()
    }
    
    override func shouldIncrement() -> Bool {
        false
    }
    
    override func getQuickActionDescription() -> String {
        "key_event_action_zoom_out"
    }
    
    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_action_magnifier_minus")
    }
}
