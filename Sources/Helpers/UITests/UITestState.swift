//
//  UITestState.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 03.09.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class UITestState: NSObject {
    enum LaunchArgument {
        enum ContextMenu {
            static let presentationRace = "-ui-testing-context-menu-presentation-race"
            static let gpxWaypointOpenTrack = "-ui-testing-gpx-waypoint-open-track"
        }
    }

    static var isContextMenuPresentationRaceEnabled: Bool {
        AppEnvironment.isUITesting && hasLaunchArgument(LaunchArgument.ContextMenu.presentationRace)
    }

    static var isGpxWaypointOpenTrackEnabled: Bool {
        AppEnvironment.isUITesting && hasLaunchArgument(LaunchArgument.ContextMenu.gpxWaypointOpenTrack)
    }

    private static var contextMenuPresentationRaceFixtureStarted = false
    private static var gpxWaypointOpenTrackFixtureStarted = false

    static func shouldRunContextMenuPresentationRaceFixture() -> Bool {
        shouldRunFixture(
            isEnabled: isContextMenuPresentationRaceEnabled,
            started: &contextMenuPresentationRaceFixtureStarted
        )
    }

    static func shouldRunGpxWaypointOpenTrackFixture() -> Bool {
        shouldRunFixture(
            isEnabled: isGpxWaypointOpenTrackEnabled,
            started: &gpxWaypointOpenTrackFixtureStarted
        )
    }

    private static func hasLaunchArgument(_ argument: String) -> Bool {
        ProcessInfo.processInfo.arguments.contains(argument)
    }

    private static func shouldRunFixture(isEnabled: Bool, started: inout Bool) -> Bool {
        guard isEnabled, !started else {
            return false
        }
        started = true
        return true
    }
}
