// Copyright © 2026 OsmAnd. All rights reserved.

import OsmAndShared

/// Navigation content and state, corresponding to Android's NavigationNotification.
@available(iOS 16.2, *)
@MainActor
final class NavigationLiveActivity: BaseLiveActivity {
    init() {
        super.init(kind: .navigation, relevanceScore: 1)
    }

    override func isActive() -> Bool {
        let routingHelper = OARoutingHelper.sharedInstance()
        return (routingHelper.isFollowingMode() || routingHelper.isPauseNavigation()) && !routingHelper.isPublicTransportMode()
    }

    override func isRunning() -> Bool {
        OARoutingHelper.sharedInstance().isFollowingMode()
    }

    override func isEnabled() -> Bool {
        OAAppSettings.sharedManager().navigationLiveActivityEnabled.get(OARoutingHelper.sharedInstance().getAppMode())
    }

    override func buildContent() async -> LiveActivityContent? {
        let routingHelper = OARoutingHelper.sharedInstance()
        let snapshot: NavigationSnapshot = await withCheckedContinuation { continuation in
            routingHelper.readNavigationSnapshot { snapshot in
                continuation.resume(returning: snapshot)
            }
        }
        var content = LiveActivityContent()
        let remainingDistance = max(0, snapshot.remainingDistance)
        let remainingDuration = max(0, snapshot.remainingDuration)
        if snapshot.isRouteCalculated {
            content.distanceText = OAOsmAndFormatter.getFormattedDistance(Float(remainingDistance), mode: routingHelper.getAppMode(), with: .useLowerBounds) ?? ""
            content.durationText = OAOsmAndFormatter.getFormattedDuration(remainingDuration) ?? ""
        }
        content.turnTypeValue = snapshot.turnTypeValue
        content.turnAngle = snapshot.turnAngle
        content.exitNumber = snapshot.exitNumber
        content.turnID = snapshot.turnID
        if routingHelper.isPauseNavigation() {
            content.phase = .paused
            content.title = localizedString("shared_string_paused")
        } else if !snapshot.isRouteCalculated {
            let error = snapshot.calculationError
            content.phase = .calculating
            content.title = localizedString("shared_string_navigation")
            content.subtitle = error.isEmpty ? localizedString("route_calculation") + "..." : LiveActivityContent.truncateToUTF8ByteLimit(error)
        } else if snapshot.isDeviatedFromRoute {
            content.turnTypeValue = TurnType.companion.OFFR
            content.turnAngle = 0
            content.exitNumber = 0
            content.title = localizedString("announcement_time_off_route")
            content.turnDistanceText = OAOsmAndFormatter.getFormattedDistance(Float(snapshot.routeDeviation), mode: routingHelper.getAppMode(), with: .useLowerBounds) ?? ""
        } else {
            content.title = LiveActivityContent.truncateToUTF8ByteLimit(snapshot.instruction)
            content.subtitle = LiveActivityContent.truncateToUTF8ByteLimit(snapshot.streetName)
            if snapshot.turnDistance >= 0 {
                content.turnDistanceText = OAOsmAndFormatter.getFormattedDistance(Float(snapshot.turnDistance), mode: routingHelper.getAppMode(), with: .useLowerBounds) ?? ""
            }
            let arrivalTime = Date().addingTimeInterval(remainingDuration)
            // The card displays hours and minutes. Ignore invisible second changes when comparing content.
            content.arrivalTime = Calendar.current.dateInterval(of: .minute, for: arrivalTime)?.start
            content.progress = snapshot.progress
        }
        return content
    }
}
