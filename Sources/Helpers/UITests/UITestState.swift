//
//  UITestState.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 03.09.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class UITestState: NSObject {
    enum LaunchArgument {
        enum ContextMenu {
            static let presentationRace = "-ui-testing-context-menu-presentation-race"
            static let gpxWaypointOpenTrack = "-ui-testing-gpx-waypoint-open-track"
        }

        static let planRouteHistory = "-ui-testing-plan-route-history"
    }

    static var isContextMenuPresentationRaceEnabled: Bool {
        AppEnvironment.isUITesting && hasLaunchArgument(LaunchArgument.ContextMenu.presentationRace)
    }

    static var isGpxWaypointOpenTrackEnabled: Bool {
        AppEnvironment.isUITesting && hasLaunchArgument(LaunchArgument.ContextMenu.gpxWaypointOpenTrack)
    }

    static var isPlanRouteHistoryEnabled: Bool {
        AppEnvironment.isUITesting && hasLaunchArgument(LaunchArgument.planRouteHistory)
    }

    private static var contextMenuPresentationRaceFixtureStarted = false
    private static var gpxWaypointOpenTrackFixtureStarted = false
    private static var planRouteHistoryFixtureStarted = false

    static func shouldRunPlanRouteHistoryFixture() -> Bool {
        shouldRunFixture(isEnabled: isPlanRouteHistoryEnabled, started: &planRouteHistoryFixtureStarted)
    }

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

#if OSMAND_UI_TESTING
final class PlanRouteUITestStateView: UIView {
    var snapshot: (() -> [String: Any]?)?

    override var accessibilityValue: String? {
        get {
            guard let snapshot = snapshot?(),
                  let data = try? JSONSerialization.data(withJSONObject: snapshot, options: .sortedKeys) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set { }
    }
}
#endif
