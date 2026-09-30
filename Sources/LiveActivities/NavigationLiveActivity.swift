// Copyright © 2026 OsmAnd. All rights reserved.

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

    override func buildContent() -> LiveActivityContent? {
        let routingHelper = OARoutingHelper.sharedInstance()
        var content = LiveActivityContent()
        let isNavigationPaused = routingHelper.isPauseNavigation()
        let isRouteCalculated = routingHelper.isRouteCalculated()
        let routeInfo = routingHelper.liveActivityRouteInfo()
        let remainingDistance = max(0, Double(routingHelper.getLeftDistance()))
        let remainingDuration = max(0, Double(routingHelper.getLeftTime()))
        if isRouteCalculated {
            content.distanceText = OAOsmAndFormatter.getFormattedDistance(Float(remainingDistance), mode: routingHelper.getAppMode(), with: .useLowerBounds) ?? ""
            content.durationText = OAOsmAndFormatter.getFormattedDuration(remainingDuration) ?? ""
        }
        content.speedText = formattedCurrentSpeed(isPaused: isNavigationPaused)
        content.turnType = routeInfo.turnType
        content.turnID = routeInfo.turnID
        if isNavigationPaused {
            content.phase = .paused
            content.title = localizedString("shared_string_paused")
        } else if !isRouteCalculated {
            let error = routingHelper.getLastRouteCalcErrorShort() ?? ""
            content.phase = .calculating
            content.title = localizedString("shared_string_navigation")
            content.subtitle = error.isEmpty ? localizedString("route_calculation") + "..." : LiveActivityContent.truncateToUTF8ByteLimit(error)
        } else if OARoutingHelper.isDeviatedFromRoute() {
            content.turnType = TurnType.companion.valueOf(value: TurnType.companion.OFFR, leftSide: false)
            content.title = localizedString("announcement_time_off_route")
            content.turnDistanceText = OAOsmAndFormatter.getFormattedDistance(Float(routingHelper.getRouteDeviation()), mode: routingHelper.getAppMode(), with: .useLowerBounds) ?? ""
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
