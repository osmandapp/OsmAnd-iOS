//
//  PlanRouteStubDataProvider.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteStubDataProvider: PlanRouteDataProvider {
    let mode: PlanRouteMode

    init(mode: PlanRouteMode = .newRoute) {
        self.mode = mode
    }

    var hasChanges: Bool {
        false
    }

    var canUndo: Bool {
        false
    }

    var canRedo: Bool {
        false
    }

    var routeInfo: PlanRouteInfo {
        PlanRouteInfo(isNewRoute: mode.isNewRoute,
                      isStraightLine: false,
                      hasRoute: !routePoints.isEmpty,
                      totalDistance: 0,
                      duration: 0,
                      arrivalTime: nil,
                      uphill: 0,
                      downhill: 0,
                      mapCenterDistance: 0,
                      bearing: 100)
    }

    var elevationData: PlanRouteElevationData? {
        nil
    }

    var poiPoints: [PlanRoutePoint] {
        []
    }

    var routePoints: [PlanRoutePoint] {
        []
    }

    var segments: [PlanRouteSegment] {
        []
    }
}
