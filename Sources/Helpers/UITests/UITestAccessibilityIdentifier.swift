//
//  UITestAccessibilityIdentifier.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 03.09.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class UITestAccessibilityIdentifier: NSObject {

    enum ContextMenu {
        static let container = "context_menu_container"
        static let multiContainer = "multi_context_menu_container"
        static let presentationState = "context_menu_presentation_test_state"

        enum GPX {
            static let trackMenuTitle = "gpx_track_menu_title"
            static let waypointPrefix = "gpx_track_menu_waypoint_"
            static let waypointOpenTrackButton = "gpx_waypoint_open_track_button"

            static func waypoint(_ title: String) -> String {
                waypointPrefix + title
            }
        }
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
}
