//
//  CommandToActionConverter.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class CommandToActionConverter {

    private static let map: [String: QuickActionType] = [
        "back_to_location": MoveToMyLocationAction.type,
        "switch_compass_forward": ChangeMapOrientationAction.type,
        "open_navigation_dialog": OpenNavigationViewAction.type,
        "open_quick_search_dialog": OpenSearchViewAction.type,
        "switch_app_mode_forward": NextAppProfileAction.quickActionType(),
        "switch_app_mode_backward": PreviousAppProfileAction.quickActionType(),
        
        "map_scroll_up": MapScrollUpAction.quickActionType(),
        "map_scroll_down": MapScrollDownAction.quickActionType(),
        "map_scroll_left": MapScrollLeftAction.quickActionType(),
        "map_scroll_right": MapScrollRightAction.quickActionType(),
        "zoom_in": MapZoomInAction.quickActionType(),
        "zoom_out": MapZoomOutAction.quickActionType(),
        
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
