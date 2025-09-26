//
//  KeyEventCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 22.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

enum KeyEventCommand: String {
    case mapZoomIn = "zoom_in"
    case mapZoomOut = "zoom_out"
    case mapScrollUp = "map_scroll_up"
    case mapScrollDown = "map_scroll_down"
    case mapScrollLeft = "map_scroll_left"
    case mapScrollRight = "map_scroll_right"
    case openWunderLINQDatagrid = "open_wunderlinq_datagrid"
    case backToLocation = "back_to_location"
    case switchCompass = "switch_compass_forward"
    case openNavigationDialog = "open_navigation_dialog"
    case openQuickSearchDialog = "open_quick_search_dialog"
    case switchAppModeToNext = "switch_app_mode_forward"
    case switchAppModeToPrevius = "switch_app_mode_backward"
    case toggleDrawer = "toggle_drawer"
    case activityBackPressed = "activity_back_pressed"
}
