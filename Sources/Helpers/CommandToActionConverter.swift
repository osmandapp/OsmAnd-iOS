//
//  CommandToActionConverter.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class CommandToActionConverter {

    private static let map: [String: QuickActionType] = [
        "back_to_location": MoveToMyLocationAction.getType(),
        "switch_compass_forward": ChangeMapOrientationAction.getType(),
        "open_navigation_dialog": OpenNavigationViewAction.getType(),
        "open_quick_search_dialog": OpenSearchViewAction.getType(),
        "switch_app_mode_forward": NextAppProfileAction.getType(),
        "switch_app_mode_backward": PreviousAppProfileAction.getType(),
        
        "map_scroll_up": MapScrollUpAction.getType(),
        "map_scroll_down": MapScrollDownAction.getType(),
        "map_scroll_left": MapScrollLeftAction.getType(),
        "map_scroll_right": MapScrollRightAction.getType(),
        "zoom_in": MapZoomInAction.getType(),
        "zoom_out": MapZoomOutAction.getType(),
        
        "toggle_drawer": ShowHideDrawerAction.getType(),
        "activity_back_pressed": NavigatePreviousScreenAction.getType(),
        "open_wunderlinq_datagrid": OpenWunderLINQDatagridAction.getType()
    ]

    static func createQuickAction(with commandId: String) -> OAQuickAction? {
        guard let type = map[commandId] else { return nil }
        return type.createNew()
    }
}
