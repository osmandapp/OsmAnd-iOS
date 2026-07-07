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
    var onRouteInfoChanged: (() -> Void)?
    var onChangeRouteTypeBefore: ((Int) -> Void)? {
        didSet { bridge.onChangeRouteTypeBefore = onChangeRouteTypeBefore }
    }
    var onChangeRouteTypeAfter: ((Int) -> Void)? {
        didSet { bridge.onChangeRouteTypeAfter = onChangeRouteTypeAfter }
    }

    weak var presenterViewController: UIViewController? {
        get { bridge.presenterViewController }
        set { bridge.presenterViewController = newValue }
    }

    var hasChanges: Bool {
        bridge.hasChanges
    }

    var hasPoints: Bool {
        bridge.hasPoints
    }

    var canUndo: Bool {
        bridge.canUndo
    }

    var canRedo: Bool {
        bridge.canRedo
    }

    var routeInfo: PlanRouteInfo {
        if let cachedRouteInfo {
            return cachedRouteInfo
        }
        let segments = bridgeSegments()
        let isStraightLine = !segments.isEmpty && segments.allSatisfy { !$0.routed }
        let analysis = cachedAnalysisData
        let duration: TimeInterval = analysis?.timeInMotion ?? 0
        let uphill: Double = analysis?.uphill ?? 0
        let downhill: Double = analysis?.downhill ?? 0
        let arrivalTime: Date? = duration > 0 && !isStraightLine ? Date(timeIntervalSinceNow: duration) : nil
        let routeInfo = PlanRouteInfo(isNewRoute: mode.isNewRoute,
                                      isStraightLine: isStraightLine,
                                      hasRoute: bridge.hasRoute,
                                      totalDistance: bridge.routeDistance,
                                      duration: duration,
                                      arrivalTime: arrivalTime,
                                      uphill: uphill,
                                      downhill: downhill,
                                      mapCenterDistance: bridge.distanceToMapCenter,
                                      bearing: bridge.bearingToMapCenter)
        cachedRouteInfo = routeInfo
        return routeInfo
    }

    var elevationData: PlanRouteElevationData? {
        nil
    }

    var isCalculatingElevation: Bool {
        bridge.isCalculatingElevation
    }

    var isCalculatingRoute: Bool {
        bridge.isCalculatingRoute
    }

    var analysisData: PlanRouteAnalysisData? {
        if hasCachedAnalysisData {
            return cachedAnalysisData
        }
        let gpxFile: GpxFile?
        switch mode {
        case .editTrack:
            gpxFile = bridge.currentGpxFile
        case .newRoute:
            gpxFile = bridge.exportedGpxFile
        }
        guard let gpxFile else {
            hasCachedAnalysisData = true
            cachedAnalysisData = nil
            return nil
        }
        let analysis = gpxFile.getAnalysis(fileTimestamp: 0)
        let hasElevation = analysis.hasElevationData()
        let stats = bridge.calculateRouteStatistics()
        let analysisData = PlanRouteAnalysisData(
            uphill: analysis.diffElevationUp,
            downhill: analysis.diffElevationDown,
            altMin: analysis.minElevation,
            altMax: analysis.maxElevation,
            avgSpeed: analysis.avgSpeed > 0 ? Double(analysis.avgSpeed) : nil,
            maxSpeed: analysis.maxSpeed > 0 ? Double(analysis.maxSpeed) : nil,
            timeInMotion: analysis.timeMoving > 0 ? TimeInterval(analysis.timeMoving) / 1000 : nil,
            hasElevationData: hasElevation,
            gpxAnalysis: analysis,
            gpxFile: gpxFile,
            routeStatistics: stats
        )
        cachedAnalysisData = analysisData
        hasCachedAnalysisData = true
        cachedRouteInfo = nil
        return analysisData
    }

    var poiGroups: [PlanRoutePoiGroup] {
        var groups = Dictionary(grouping: bridge.buildPoiItems(), by: { poiGroupName(for: $0) })
            .map { PlanRoutePoiGroup(name: $0.key, points: $0.value.map { mapPoiPoint($0) }) }
        let existingNames = Set(groups.map(\.name))
        groups.append(contentsOf: bridge.buildPoiGroupNames()
            .filter { !existingNames.contains($0) }
            .map { PlanRoutePoiGroup(name: $0, points: []) })
        return groups.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var routeSegments: [PlanRouteSegment] {
        if let cachedRouteSegments {
            return cachedRouteSegments
        }
        let segments = bridgeSegments().map { mapSegment($0) }
        cachedRouteSegments = segments
        return segments
    }

    var defaultMode: OAApplicationMode? {
        bridge.defaultAppMode
    }

    var canStartNewSegment: Bool {
        bridge.isAddNewSegmentAllowed
    }

    var availableModes: [OAApplicationMode] {
        bridge.availableModes()
    }

    var routeGpxFile: GpxFile? {
        bridge.exportedGpxFile
    }

    private let bridge = OAPlanRouteEditingBridge()
    private let filePath: String?
    private var cachedBridgeSegments: [OAPlanRouteSegmentData]?
    private var cachedRouteInfo: PlanRouteInfo?
    private var cachedRouteSegments: [PlanRouteSegment]?
    private var cachedAnalysisData: PlanRouteAnalysisData?
    private var hasCachedAnalysisData = false
    private var routingParamsCache: [String: PlanRouteSegmentRoutingParams] = [:]

    init(mode: PlanRouteMode = .newRoute, filePath: String? = nil) {
        self.mode = mode
        self.filePath = filePath
        bridge.onChange = { [weak self] in
            self?.invalidateCachedData()
            self?.onDataChanged?()
        }
        bridge.onRouteInfoChanged = { [weak self] in
            self?.invalidateRouteInfoCache()
            self?.onRouteInfoChanged?()
        }
        if mode.isEditTrack, let filePath {
            bridge.openTrack(withFilePath: filePath)
        } else {
            bridge.prepareNewRoute()
        }
    }

    func startElevationCalculation(useNearbyRoads: Bool) {
        bridge.startElevationCalculation(withNearbyRoads: useNearbyRoads)
    }

    func cancelElevationCalculation() {
        bridge.cancelElevationCalculation()
    }

    func addRoutePoint() {
        NSLog("[PlanRouteDbg] addRoutePoint (center point)")
        bridge.addCenterPoint()
    }

    func openAddPoi(from presentingViewController: UIViewController) {
        guard mode.isNewRoute || (filePath?.isEmpty == false) else { return }
        bridge.openAddPoi(withFilePath: filePath, presenting: presentingViewController)
    }

    func addPoiGroup(_ name: String) {
        bridge.addPoiGroup(name)
    }

    func renamePoiGroup(from oldName: String, to newName: String) {
        bridge.renamePoiGroup(from: oldName, to: newName)
    }

    func openPoiGroupAppearance(_ groupName: String, from presentingViewController: UIViewController) {
        bridge.openPoiGroupAppearance(groupName, presenting: presentingViewController)
    }

    func deletePoiGroup(_ groupName: String) {
        bridge.deletePoiGroup(groupName)
    }

    func openEditPoiPoint(_ point: PlanRoutePoiPoint, from presentingViewController: UIViewController) {
        bridge.openEditPoiPoint(point.item, presenting: presentingViewController)
    }

    func deletePoiPoint(_ point: PlanRoutePoiPoint) {
        bridge.deletePoiPoint(point.item)
    }

    func undo() {
        bridge.undo()
    }

    func redo() {
        bridge.redo()
    }

    func reverseRoute() {
        bridge.reverseRoute()
    }

    func clearAllPoints() {
        bridge.clearAllPoints()
    }

    func saveAs(fileName: String, folder: String?, showOnMap: Bool, onComplete: @escaping (Bool, String?) -> Void) {
        bridge.save(as: fileName, folder: folder, showOnMap: showOnMap, onComplete: onComplete)
    }

    func saveAsCopy(fileName: String, folder: String?, showOnMap: Bool, onComplete: @escaping (Bool, String?) -> Void) {
        bridge.save(asCopy: fileName, folder: folder, showOnMap: showOnMap, onComplete: onComplete)
    }

    func appendToTrack(filePath: String, onComplete: @escaping (Bool) -> Void) {
        bridge.append(toTrack: filePath, onComplete: onComplete)
    }

    func enterNavigation() {
        bridge.enterNavigation(withTrackName: mode.title)
    }

    func setCrosshairPosition(screenPoint: CGPoint) {
        bridge.setCrosshairScreenPoint(screenPoint)
    }

    func dismissLayer() {
        bridge.dismiss()
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
        NSLog("[PlanRouteDbg] startNewSegment")
        bridge.startNewSegment()
    }

    func applyMode(_ mode: OAApplicationMode, pointIndex: Int, wholeRoute: Bool) {
        NSLog("[PlanRouteDbg] applyMode: mode=%@ pointIndex=%d wholeRoute=%@",
              mode.stringKey ?? "nil", pointIndex, wholeRoute ? "true" : "false")
        bridge.apply(mode, pointIndex: pointIndex, wholeRoute: wholeRoute)
    }

    func applyModeToContext(_ mode: OAApplicationMode?, context: SegmentRouteContext) {
        guard let effectiveMode = mode ?? OAApplicationMode.default() else { return }
        NSLog("[PlanRouteDbg] applyModeToContext: mode=%@ context=%@",
              effectiveMode.stringKey ?? "nil", String(describing: context))
        if case let .profileGroup(group, _) = context {
            NSLog("[PlanRouteDbg] applyModeToContext profileGroup: pointsCount=%d indices=%@",
                  group.points.count,
                  group.points.map { String($0.index) }.joined(separator: ","))
            for point in group.points {
                NSLog("[PlanRouteDbg]   bridge.apply mode=%@ pointIndex=%d wholeRoute=false",
                      effectiveMode.stringKey ?? "nil", point.index)
                bridge.apply(effectiveMode, pointIndex: point.index, wholeRoute: false)
            }
        } else {
            NSLog("[PlanRouteDbg] applyModeToContext other: applyPointIndex=%d wholeRoute=%@",
                  context.applyPointIndex, context.applyWholeRoute ? "true" : "false")
            bridge.apply(effectiveMode, pointIndex: context.applyPointIndex, wholeRoute: context.applyWholeRoute)
        }
    }

    func applyModeAllNext(fromPointIndex index: Int, mode: OAApplicationMode?) {
        NSLog("[PlanRouteDbg] applyModeAllNext: fromIndex=%d mode=%@",
              index, mode?.stringKey ?? "nil")
        bridge.applyModeAllNext(fromIndex: index, appMode: mode ?? OAApplicationMode.default())
    }

    func sortDoorToDoor(pointIndexes: [Int]) {
        bridge.sortSegmentDoorToDoor(withPointIndexes: pointIndexes.map { NSNumber(value: $0) })
    }

    func moveSegment(from srcIdx: Int, to dstIdx: Int) {
        guard srcIdx != dstIdx else { return }
        bridge.reorderSegment(from: srcIdx, to: dstIdx)
    }

    func saveSegment(pointIndexes: [Int]) {
        let fileName = mode.title
        bridge.saveSegment(withPointIndexes: pointIndexes.map { NSNumber(value: $0) },
                           fileName: fileName,
                           showOnMap: true) { _, _ in }
    }

    func selectRoutePoint(at index: Int) {
        bridge.selectPoint(at: index)
    }

    func showPointOptions(at index: Int) {
        bridge.showPointOptions(at: index)
    }

    func addPointBefore(index: Int) {
        NSLog("[PlanRouteDbg] addPointBefore: index=%d", index)
        bridge.addPointBefore(index: index)
    }

    func addPointAfter(index: Int) {
        NSLog("[PlanRouteDbg] addPointAfter: index=%d", index)
        bridge.addPointAfter(index: index)
    }

    func trimBefore(index: Int) {
        bridge.trimBefore(index: index)
    }

    func trimAfter(index: Int) {
        bridge.trimAfter(index: index)
    }

    func routingParams(for context: SegmentRouteContext) -> PlanRouteSegmentRoutingParams {
        let key = cacheKey(for: context)
        return routingParamsCache[key] ?? PlanRouteSegmentRoutingParams(useElevationData: false, considerTemporaryLimitations: true)
    }

    func applyRoutingParams(_ params: PlanRouteSegmentRoutingParams, for context: SegmentRouteContext) {
        let key = cacheKey(for: context)
        routingParamsCache[key] = params
    }

    private func cacheKey(for context: SegmentRouteContext) -> String {
        switch context {
        case let .profileGroup(group, segment):
            return "group_\(segment.index)_\(group.lastPointIndex)"
        case let .wholeSegment(segment):
            return "segment_\(segment.index)"
        case .wholeTrack:
            return "whole"
        }
    }

    private func bridgeSegments() -> [OAPlanRouteSegmentData] {
        if let cachedBridgeSegments {
            return cachedBridgeSegments
        }
        let segments = bridge.buildSegments()
        cachedBridgeSegments = segments
        return segments
    }

    private func invalidateCachedData() {
        cachedBridgeSegments = nil
        invalidateRouteInfoCache()
        cachedRouteSegments = nil
        cachedAnalysisData = nil
        hasCachedAnalysisData = false
    }

    private func invalidateRouteInfoCache() {
        cachedRouteInfo = nil
    }

    private func mapSegment(_ segment: OAPlanRouteSegmentData) -> PlanRouteSegment {
        NSLog("[PlanRouteDbg] mapSegment: index=%d groupsCount=%d multiMode=%@ routed=%@ distance=%.1f singleMode=%@",
              segment.index, segment.groups.count,
              segment.multiMode ? "true" : "false",
              segment.routed ? "true" : "false",
              segment.distance,
              segment.singleMode?.stringKey ?? "nil")
        return PlanRouteSegment(index: segment.index,
                                groups: segment.groups.map { mapGroup($0) },
                                routed: segment.routed,
                                multiMode: segment.multiMode,
                                singleMode: segment.singleMode,
                                distance: segment.distance)
    }

    private func poiGroupName(for item: OAGpxWptItem) -> String {
        let category = item.point.category ?? ""
        return category.isEmpty ? localizedString("shared_string_gpx_points") : category
    }

    private func mapPoiPoint(_ item: OAGpxWptItem) -> PlanRoutePoiPoint {
        let name = item.point.name ?? ""
        return PlanRoutePoiPoint(name: name.isEmpty ? localizedString("shared_string_waypoint") : name,
                                 subtitle: item.point.getAddress() ?? "",
                                 icon: item.compositeIconWithDefaultColor(),
                                 item: item)
    }

    private func mapGroup(_ group: OAPlanRouteGroupData) -> PlanRouteProfileGroup {
        let pointIndices = group.points.map { $0.globalIndex }
        NSLog("[PlanRouteDbg] mapGroup: appMode=%@ distance=%.1f lastGlobalIndex=%d pointsCount=%d pointIndices=%@",
              group.appMode?.stringKey ?? "nil",
              group.distance,
              group.lastGlobalIndex,
              group.points.count,
              pointIndices.map { String($0) }.joined(separator: ","))
        return PlanRouteProfileGroup(appMode: group.appMode,
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
