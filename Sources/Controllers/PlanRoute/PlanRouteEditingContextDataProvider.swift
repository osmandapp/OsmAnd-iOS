//
//  PlanRouteEditingContextDataProvider.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 17.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteEditingContextDataProvider: PlanRouteDataProvider {
    let mode: PlanRouteMode

    var onDataChanged: (() -> Void)?

    private let bridge = OAPlanRouteEditingBridge()

    init(mode: PlanRouteMode = .newRoute, filePath: String? = nil) {
        self.mode = mode
        bridge.onChange = { [weak self] in self?.onDataChanged?() }
        if mode.isEditTrack, let filePath {
            bridge.openTrack(withFilePath: filePath)
        } else {
            bridge.prepareNewRoute()
        }
    }

    var hasChanges: Bool {
        bridge.hasChanges
    }

    var canUndo: Bool {
        bridge.canUndo
    }

    var canRedo: Bool {
        bridge.canRedo
    }

    var routeInfo: PlanRouteInfo {
        PlanRouteInfo(isNewRoute: mode.isNewRoute,
                      isStraightLine: false,
                      hasRoute: bridge.hasRoute,
                      totalDistance: bridge.routeDistance,
                      duration: 0,
                      arrivalTime: nil,
                      uphill: 0,
                      downhill: 0,
                      mapCenterDistance: 0,
                      bearing: 0)
    }

    var elevationData: PlanRouteElevationData? {
        nil
    }

    var poiPoints: [PlanRoutePoint] {
        []
    }

    var routeSegments: [PlanRouteSegment] {
        bridge.buildSegments().map { mapSegment($0) }
    }

    var canStartNewSegment: Bool {
        bridge.isAddNewSegmentAllowed
    }

    var availableModes: [OAApplicationMode] {
        bridge.availableModes()
    }

    func addRoutePoint() {
        bridge.addCenterPoint()
    }

    func undo() {
        bridge.undo()
    }

    func redo() {
        bridge.redo()
    }

    func moveRoutePoint(from: Int, to: Int) {
        bridge.movePoint(from: from, to: to)
    }

    func deleteRoutePoint(at index: Int) {
        bridge.deletePoint(at: index)
    }

    func deleteSegment(pointIndexes: [Int]) {
        bridge.deleteSegment(withPointIndexes: pointIndexes.map { NSNumber(value: $0) })
    }

    func startNewSegment() {
        bridge.startNewSegment()
    }

    func applyMode(_ mode: OAApplicationMode, pointIndex: Int, wholeRoute: Bool) {
        bridge.apply(mode, pointIndex: pointIndex, wholeRoute: wholeRoute)
    }

    func sortDoorToDoor(pointIndexes: [Int]) {
        bridge.sortSegmentDoorToDoor(withPointIndexes: pointIndexes.map { NSNumber(value: $0) })
    }

    func saveSegment(pointIndexes: [Int]) {
    }

    func selectRoutePoint(at index: Int) {
        bridge.selectPoint(at: index)
    }

    private func mapSegment(_ segment: OAPlanRouteSegmentData) -> PlanRouteSegment {
        PlanRouteSegment(index: segment.index,
                         groups: segment.groups.map { mapGroup($0) },
                         routed: segment.routed,
                         multiMode: segment.multiMode,
                         singleMode: segment.singleMode,
                         distance: segment.distance)
    }

    private func mapGroup(_ group: OAPlanRouteGroupData) -> PlanRouteProfileGroup {
        PlanRouteProfileGroup(appMode: group.appMode,
                              distance: group.distance,
                              lastPointIndex: group.lastGlobalIndex,
                              points: group.points.map { mapPoint($0) })
    }

    private func mapPoint(_ point: OAPlanRoutePointData) -> PlanRoutePoint {
        PlanRoutePoint(index: point.globalIndex,
                       name: point.name,
                       distanceFromPrevious: point.distanceFromPrevious,
                       bearing: point.bearing,
                       isStart: point.isStart,
                       isDestination: point.isDestination)
    }
}
