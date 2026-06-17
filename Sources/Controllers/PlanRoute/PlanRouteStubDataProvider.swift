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
                      hasRoute: !routeSegments.isEmpty,
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

    var routeSegments: [PlanRouteSegment] {
        guard mode.isEditTrack else { return [] }
        return [sampleSegment]
    }

    var canStartNewSegment: Bool {
        mode.isEditTrack
    }

    private var sampleSegment: PlanRouteSegment {
        let cyclingPoints = [
            PlanRoutePoint(index: 0, name: "Point - 1", distanceFromPrevious: 0, bearing: 100, isStart: true, isDestination: false),
            PlanRoutePoint(index: 1, name: "Point - 2", distanceFromPrevious: 100, bearing: 100, isStart: false, isDestination: false)
        ]
        let walkingPoints = [
            PlanRoutePoint(index: 2, name: "Point - 3", distanceFromPrevious: 200, bearing: 100, isStart: false, isDestination: false),
            PlanRoutePoint(index: 3, name: "Point - 4", distanceFromPrevious: 5000, bearing: 100, isStart: false, isDestination: false),
            PlanRoutePoint(index: 4, name: "Point - 5", distanceFromPrevious: 3580, bearing: 100, isStart: false, isDestination: true)
        ]
        let groups = [
            PlanRouteProfileGroup(appMode: OAApplicationMode.bicycle(), distance: 53000, lastPointIndex: 1, points: cyclingPoints),
            PlanRouteProfileGroup(appMode: OAApplicationMode.pedestrian(), distance: 120000, lastPointIndex: 4, points: walkingPoints)
        ]
        return PlanRouteSegment(index: 0, groups: groups, routed: true, multiMode: true, singleMode: nil, distance: 173000)
    }

    var availableModes: [OAApplicationMode] {
        OAApplicationMode.values()
    }

    func deleteRoutePoint(at index: Int) {}

    func deleteSegment(pointIndexes: [Int]) {}

    func startNewSegment() {}

    func applyMode(_ mode: OAApplicationMode, pointIndex: Int, wholeRoute: Bool) {}

    func sortDoorToDoor(pointIndexes: [Int]) {}

    func saveSegment(pointIndexes: [Int]) {}

    func selectRoutePoint(at index: Int) {}
}
