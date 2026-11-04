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
        let routeInfo: LiveActivityRouteInfo = await withCheckedContinuation { continuation in
            routingHelper.readLiveActivityRouteInfo { info in
                continuation.resume(returning: info)
            }
        }
        var content = LiveActivityContent()
        let remainingDistance = max(0, routeInfo.remainingDistance)
        let remainingDuration = max(0, routeInfo.remainingDuration)
        if routeInfo.isRouteCalculated {
            content.distanceText = OAOsmAndFormatter.getFormattedDistance(Float(remainingDistance), mode: routingHelper.getAppMode(), with: .useLowerBounds) ?? ""
            content.durationText = OAOsmAndFormatter.getFormattedDuration(remainingDuration) ?? ""
        }
        content.turnTypeValue = routeInfo.turnTypeValue
        content.turnAngle = routeInfo.turnAngle
        content.exitNumber = routeInfo.exitNumber
        content.turnID = routeInfo.turnID
        if routingHelper.isPauseNavigation() {
            content.phase = .paused
            content.title = localizedString("shared_string_paused")
        } else if !routeInfo.isRouteCalculated {
            let error = routeInfo.calculationError
            content.phase = .calculating
            content.title = localizedString("shared_string_navigation")
            content.subtitle = error.isEmpty ? localizedString("route_calculation") + "..." : LiveActivityContent.truncateToUTF8ByteLimit(error)
        } else if routeInfo.isDeviatedFromRoute {
            content.turnTypeValue = TurnType.companion.OFFR
            content.turnAngle = 0
            content.exitNumber = 0
            content.title = localizedString("announcement_time_off_route")
            content.turnDistanceText = OAOsmAndFormatter.getFormattedDistance(Float(routeInfo.routeDeviation), mode: routingHelper.getAppMode(), with: .useLowerBounds) ?? ""
        } else {
            content.title = LiveActivityContent.truncateToUTF8ByteLimit(routeInfo.instruction)
            content.subtitle = LiveActivityContent.truncateToUTF8ByteLimit(routeInfo.streetName)
            if routeInfo.turnDistance >= 0 {
                content.turnDistanceText = OAOsmAndFormatter.getFormattedDistance(Float(routeInfo.turnDistance), mode: routingHelper.getAppMode(), with: .useLowerBounds) ?? ""
            }
            let arrivalTime = Date().addingTimeInterval(remainingDuration)
            // The card displays hours and minutes. Ignore invisible second changes when comparing content.
            content.arrivalTime = Calendar.current.dateInterval(of: .minute, for: arrivalTime)?.start
            content.progress = LiveActivityContent.routeProgress(remainingDistance: remainingDistance, totalDistance: routeInfo.totalDistance)
        }
        return content
    }
}
