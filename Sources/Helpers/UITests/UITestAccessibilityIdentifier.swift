//
//  UITestAccessibilityIdentifier.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 03.09.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class UITestAccessibilityIdentifier: NSObject {

    enum PlanRoute {
        static let state = "plan_route_test_state"
        static let sheet = "plan_route_sheet"
        static let summary = "plan_route_summary"
        static let points = "plan_route_points"
        static let undo = "plan_route_undo"
        static let redo = "plan_route_redo"
        static let add = "plan_route_add"
        static let close = "plan_route_close"
        static let options = "plan_route_options"
        static let apply = "plan_route_apply"
        static let cancel = "plan_route_cancel"

        static func point(_ index: Int) -> String {
            "plan_route_point_\(index)"
        }
    }

    enum ContextMenu {
        enum GPX {
            static let trackMenuTitle = "gpx_track_menu_title"
            static let waypointPrefix = "gpx_track_menu_waypoint_"
            static let waypointOpenTrackButton = "gpx_waypoint_open_track_button"

            static func waypoint(_ title: String) -> String {
                waypointPrefix + title
            }
        }

        static let container = "context_menu_container"
        static let multiContainer = "multi_context_menu_container"
        static let presentationState = "context_menu_presentation_test_state"
    }

    static var contextMenuContainer: String {
        ContextMenu.container
    }

    static var multiContextMenuContainer: String {
        ContextMenu.multiContainer
    }

    static var contextMenuPresentationState: String {
        ContextMenu.presentationState
    }

    static var gpxTrackMenuTitle: String {
        ContextMenu.GPX.trackMenuTitle
    }

    static var gpxTrackMenuWaypointPrefix: String {
        ContextMenu.GPX.waypointPrefix
    }

    static var gpxWaypointOpenTrackButton: String {
        ContextMenu.GPX.waypointOpenTrackButton
    }

    static func gpxTrackMenuWaypoint(_ title: String) -> String {
        ContextMenu.GPX.waypoint(title)
    }

    static func planRoutePointAction(_ key: String) -> String {
        "plan_route_point_action_" + key
    }
}
