//
//  CommandToActionConverter.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class CommandToActionConverter {

    // TODO
    private static let map: [String : QuickActionType] = [
        "back_to_location": MoveToMyLocationAction.type,
        //"switch_compass_forward": ChangeMapOrientationAction.TYPE,
        "open_navigation_dialog": OpenNavigationViewAction.type,
        "open_quick_search_dialog": OpenSearchViewAction.type,
        "switch_app_mode_forward": NextAppProfileAction.getQuickActionType(),
        "switch_app_mode_backward": PreviousAppProfileAction.getQuickActionType(),
        
        "map_scroll_up": MapScrollUpAction.getQuickActionType(),
        "map_scroll_down": MapScrollDownAction.getQuickActionType(),
        "map_scroll_left": MapScrollLeftAction.getQuickActionType(),
        "map_scroll_right": MapScrollRightAction.getQuickActionType(),
        "zoom_in": MapZoomInAction.getQuickActionType(),
        "zoom_out": MapZoomOutAction.getQuickActionType(),
        //"continuous_zoom_in": ContinuousMapZoomInAction.TYPE,
        //"continuous_zoom_out": ContinuousMapZoomOutAction.TYPE,
        
        // "emit_navigation_hint": nil,
        "toggle_drawer": ShowHideDrawerAction.type,
        "activity_back_pressed": NavigatePreviousScreenAction.type,
        // "take_media_note": nil,
        "open_wunderlinq_datagrid": OpenWunderLINQDatagridAction.type
    ]

    static func createQuickAction(with commandId: String) -> OAQuickAction? {
        guard let type = map[commandId] else { return nil }
        return type.createNew()
    }
}
