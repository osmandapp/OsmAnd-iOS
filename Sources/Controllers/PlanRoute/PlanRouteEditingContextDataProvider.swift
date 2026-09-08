//
//  PlanRouteEditingContextDataProvider.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 17.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import CoreLocation
import OsmAndShared

final class PlanRouteEditingContextDataProvider: PlanRouteDataProvider {

    let mode: PlanRouteMode

    var onDataChanged: (() -> Void)?
    var onRouteInfoChanged: (() -> Void)?
    var onPointEditModeRequested: ((PlanRoutePointEditMode) -> Void)?
    var onApproximationPopupDismissed: (() -> Void)? {
        didSet { bridge.onApproximationPopupDismissed = onApproximationPopupDismissed }
    }
    private(set) var pendingEmptySegmentIndex: Int?

    weak var presenterViewController: UIViewController? {
        get { bridge.presenterViewController }
        set { bridge.presenterViewController = newValue }
    }

    var onChangeRouteTypeBefore: ((Int) -> Void)? {
        didSet { bridge.onChangeRouteTypeBefore = onChangeRouteTypeBefore }
    }
    var onChangeRouteTypeAfter: ((Int) -> Void)? {
        didSet { bridge.onChangeRouteTypeAfter = onChangeRouteTypeAfter }
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
        scheduleAnalysisIfNeeded()
        let analysis = cachedAnalysisData
        let routeDuration = bridge.routeDuration
        let duration = routeDuration > 0 ? routeDuration : analysis?.timeInMotion ?? 0
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

    var isCalculatingElevation: Bool {
        bridge.isCalculatingElevation
    }

    var isCalculatingRoute: Bool {
        bridge.isCalculatingRoute
    }

    var isTerrainElevationAvailable: Bool {
        bridge.isTerrainElevationAvailable
    }

    var analysisData: PlanRouteAnalysisData? {
        if hasCachedAnalysisData {
            return cachedAnalysisData
        }
        scheduleAnalysisIfNeeded()
        return nil
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

    var isTrackReadyToCalculate: Bool {
        bridge.isTrackReadyToCalculate
    }

    var isApproximationNeeded: Bool {
        bridge.isApproximationNeeded
    }

    var shouldShowApproximationWarning: Bool {
        bridge.shouldShowApproximationWarning
    }

    var approximationWarningViewController: UIViewController? {
        bridge.approximationWarningViewController
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

    var editTrackFolder: String? {
        guard mode.isEditTrack, let filePath, !filePath.isEmpty else { return nil }
        var path = filePath
        if (path as NSString).isAbsolutePath, let gpxRoot = OsmAndApp.swiftInstance().gpxPath, path.hasPrefix(gpxRoot) {
            path = String(path.dropFirst(gpxRoot.count))
        }
        let folder = (path as NSString).deletingLastPathComponent.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return folder.isEmpty ? nil : folder
    }

    private let bridge = OAPlanRouteEditingBridge()
    private let filePath: String?
    private var cachedBridgeSegments: [PlanRouteSegmentData]?
    private var cachedRouteInfo: PlanRouteInfo?
    private var cachedRouteSegments: [PlanRouteSegment]?
    private var cachedAnalysisData: PlanRouteAnalysisData?
    private var hasCachedAnalysisData = false
    private var analysisGeneration = 0
    private var pendingAnalysisGeneration: Int?
    private var pendingSegmentHistoryState: (wasPending: Bool, hadTrailingGap: Bool)?
    private var initialApplicationMode: OAApplicationMode {
        var supportedModes = bridge.availableModes()
        if let directLineMode = OAApplicationMode.default() {
            supportedModes.append(directLineMode)
        }
        let currentMode = OAAppSettings.sharedManager().applicationMode.get()
        return supportedModes.first(where: { $0.stringKey == currentMode.stringKey }) ?? .default()
    }

    init(mode: PlanRouteMode = .newRoute, filePath: String? = nil, initialPoint: CLLocationCoordinate2D? = nil, applicationMode: OAApplicationMode? = nil) {
        self.mode = mode
        self.filePath = filePath
        bridge.onChange = { [weak self] in
            guard let self else { return }
            invalidateCachedData()
            updatePendingEmptySegment()
            onDataChanged?()
        }
        bridge.onNewSegmentStarted = { [weak self] in
            guard let self else { return }
            pendingEmptySegmentIndex = routeSegments.count + 1
        }
        bridge.onRouteInfoChanged = { [weak self] in
            self?.invalidateRouteInfoCache()
            self?.onRouteInfoChanged?()
        }
        bridge.onPointEditModeRequested = { [weak self] editMode in
            let mode: PlanRoutePointEditMode
            switch editMode {
            case .move:
                mode = .move
            case .addBefore:
                mode = .addBefore
            case .addAfter:
                mode = .addAfter
            @unknown default:
                return
            }
            self?.onPointEditModeRequested?(mode)
        }
        if mode.isEditTrack, let filePath {
            bridge.openTrack(withFilePath: filePath)
        } else {
            bridge.prepareNewRoute(with: applicationMode ?? initialApplicationMode)
            if let initialPoint {
                bridge.addPoint(at: initialPoint)
            }
        }
    }

    func startElevationCalculation(useNearbyRoads: Bool) {
        bridge.startElevationCalculation(withNearbyRoads: useNearbyRoads)
    }

    func cancelElevationCalculation() {
        bridge.cancelElevationCalculation()
    }

    func hideChartHighlight() {
        bridge.hideChartHighlight()
    }

    func showChartHighlightedLocation(_ points: TrackChartPoints) {
        bridge.showChartHighlightedLocation(points)
    }

    func showChartStatisticsLocation(_ points: TrackChartPoints) {
        bridge.showChartStatisticsLocation(points)
    }

    func addRoutePoint() {
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
        bridge.renamePoiGroup(fromName: oldName, toName: newName)
    }

    func openPoiGroupAppearance(_ groupName: String, from presentingViewController: UIViewController) {
        bridge.openPoiGroupAppearance(forName: groupName, presenting: presentingViewController)
    }

    func deletePoiGroup(_ groupName: String) {
        bridge.deletePoiGroup(withName: groupName)
    }

    func openEditPoiPoint(_ point: PlanRoutePoiPoint, from presentingViewController: UIViewController) {
        bridge.openEditPoiPoint(point.item, presenting: presentingViewController)
    }

    func deletePoiPoint(_ point: PlanRoutePoiPoint) {
        bridge.deletePoiPoint(point.item)
    }

    func undo() {
        pendingSegmentHistoryState = (pendingEmptySegmentIndex != nil, bridge.hasTrailingGap)
        bridge.undo()
        pendingSegmentHistoryState = nil
    }

    func redo() {
        pendingSegmentHistoryState = (pendingEmptySegmentIndex != nil, bridge.hasTrailingGap)
        bridge.redo()
        pendingSegmentHistoryState = nil
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
        bridge.startNewSegment()
    }

    func applyMode(_ mode: OAApplicationMode, pointIndex: Int, wholeRoute: Bool) {
        bridge.apply(mode, pointIndex: pointIndex, wholeRoute: wholeRoute)
    }

    func applyMode(_ mode: OAApplicationMode, pointIndexes: [Int]) {
        bridge.apply(mode, pointIndexes: pointIndexes.map { NSNumber(value: $0) })
    }

    func applyModeToContext(_ mode: OAApplicationMode?, context: SegmentRouteContext) {
        guard let effectiveMode = mode ?? OAApplicationMode.default() else { return }
        if case let .profileGroup(_, segment) = context, segment.isPendingEmpty {
            guard let pointIndex = routeSegments.last?.pointIndexes.last else { return }
            bridge.apply(effectiveMode, pointIndex: pointIndex, wholeRoute: false)
        } else if case let .profileGroup(group, _) = context {
            applyMode(effectiveMode, pointIndexes: group.points.map(\.index))
        } else if case let .wholeSegment(segment) = context {
            let pointIndexes = segment.groups.flatMap { $0.points.map(\.index) }
            applyMode(effectiveMode, pointIndexes: pointIndexes)
        } else {
            bridge.apply(effectiveMode, pointIndex: context.applyPointIndex, wholeRoute: context.applyWholeRoute)
        }
    }

    func sortDoorToDoor(pointIndexes: [Int]) {
        bridge.sortSegmentDoorToDoor(withPointIndexes: pointIndexes.map { NSNumber(value: $0) })
    }

    func moveSegment(from srcIdx: Int, to dstIdx: Int) {
        guard srcIdx != dstIdx else { return }
        bridge.reorderSegment(from: srcIdx, to: dstIdx)
    }

    func saveSegment(pointIndexes: [Int], fileName: String, showOnMap: Bool, onComplete: @escaping (Bool, String?) -> Void) {
        bridge.saveSegment(withPointIndexes: pointIndexes.map { NSNumber(value: $0) },
                           fileName: fileName,
                           showOnMap: showOnMap,
                           onComplete: onComplete)
    }

    func selectRoutePoint(at index: Int) {
        bridge.selectPoint(at: index)
    }

    func showPointOptions(at index: Int) {
        bridge.showPointOptions(at: index)
    }

    func addPointBefore(index: Int) {
        bridge.addPoint(before: index)
    }

    func addPointAfter(index: Int) {
        bridge.addPoint(after: index)
    }

    func trimBefore(index: Int) {
        bridge.trim(before: index)
    }

    func trimAfter(index: Int) {
        bridge.trim(after: index)
    }

    func applyPointEdit() {
        bridge.applyPointEdit()
    }

    func cancelPointEdit() {
        bridge.cancelPointEdit()
    }

    func addAnotherPoint() {
        bridge.addAnotherPoint()
    }

    func refreshRoute(for mode: OAApplicationMode) {
        bridge.refreshRoute(for: mode)
    }

    private func bridgeSegments() -> [PlanRouteSegmentData] {
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
        if !bridge.hasPoints {
            cachedAnalysisData = nil
        }
        hasCachedAnalysisData = false
        analysisGeneration += 1
    }

    private func invalidateRouteInfoCache() {
        cachedRouteInfo = nil
    }

    private func scheduleAnalysisIfNeeded() {
        guard bridge.hasPoints,
              !hasCachedAnalysisData,
              pendingAnalysisGeneration == nil,
              !bridge.isCalculatingRoute else { return }
        let fileTimestamp = mode.isEditTrack ? bridge.currentGpxFile?.modifiedTime ?? 0 : 0
        let gpxFile = bridge.exportedGpxFile
        guard let gpxFile else {
            hasCachedAnalysisData = true
            cachedAnalysisData = nil
            return
        }
        let stats = bridge.calculateRouteStatistics()
        let generation = analysisGeneration
        pendingAnalysisGeneration = generation
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let analysis = gpxFile.getAnalysis(
                fileTimestamp: fileTimestamp,
                fromDistance: nil,
                toDistance: nil,
                pointsAnalyzer: PlatformUtil.shared.getTrackPointsAnalyser()
            )
            let analysisData = PlanRouteAnalysisData(
                uphill: analysis.diffElevationUp,
                downhill: analysis.diffElevationDown,
                altMin: analysis.minElevation,
                altMax: analysis.maxElevation,
                avgSpeed: analysis.avgSpeed > 0 ? Double(analysis.avgSpeed) : nil,
                maxSpeed: analysis.maxSpeed > 0 ? Double(analysis.maxSpeed) : nil,
                timeInMotion: analysis.timeMoving > 0 ? TimeInterval(analysis.timeMoving) / 1000 : nil,
                hasElevationData: analysis.hasElevationData(),
                hasSpeedData: analysis.isSpeedSpecified(),
                gpxAnalysis: analysis,
                gpxFile: gpxFile,
                routeStatistics: stats
            )
            DispatchQueue.main.async { [weak self] in
                guard let self, pendingAnalysisGeneration == generation else { return }
                pendingAnalysisGeneration = nil
                guard analysisGeneration == generation else {
                    scheduleAnalysisIfNeeded()
                    return
                }
                cachedAnalysisData = analysisData
                hasCachedAnalysisData = true
                invalidateRouteInfoCache()
                onDataChanged?()
            }
        }
    }

    private func updatePendingEmptySegment() {
        let hasTrailingGap = bridge.hasTrailingGap
        let shouldShowPendingSegment: Bool
        if let pendingSegmentHistoryState {
            shouldShowPendingSegment = hasTrailingGap
                && (pendingSegmentHistoryState.wasPending || !pendingSegmentHistoryState.hadTrailingGap)
        } else {
            shouldShowPendingSegment = pendingEmptySegmentIndex != nil && hasTrailingGap
        }
        pendingEmptySegmentIndex = shouldShowPendingSegment ? bridgeSegments().count + 1 : nil
    }

    private func mapSegment(_ segment: PlanRouteSegmentData) -> PlanRouteSegment {
        let gapAfter = segment.hasGapAfter
            ? PlanRouteSegmentGap(distance: segment.gapDistance, bearing: segment.gapBearing)
            : nil
        var distanceFromStart = 0.0
        var groups: [PlanRouteProfileGroup] = []
        for group in segment.groups {
            groups.append(mapGroup(group, distanceFromStart: &distanceFromStart))
        }
        return PlanRouteSegment(index: segment.index,
                                groups: groups,
                                routed: segment.routed,
                                multiMode: segment.multiMode,
                                singleMode: segment.singleMode,
                                distance: segment.distance,
                                isPendingEmpty: false,
                                gapAfter: gapAfter)
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

    private func mapGroup(_ group: PlanRouteGroupData, distanceFromStart: inout Double) -> PlanRouteProfileGroup {
        var points: [PlanRoutePoint] = []
        for point in group.points {
            distanceFromStart += point.distanceFromPrevious
            points.append(mapPoint(point, distanceFromStart: distanceFromStart))
        }
        return PlanRouteProfileGroup(appMode: group.appMode,
                                     distance: group.distance,
                                     lastPointIndex: group.lastGlobalIndex,
                                     points: points)
    }

    private func mapPoint(_ point: PlanRoutePointData, distanceFromStart: Double) -> PlanRoutePoint {
        PlanRoutePoint(index: point.globalIndex,
                       indexInSegment: point.indexInSegment,
                       name: point.name,
                       distanceFromPrevious: point.distanceFromPrevious,
                       distanceFromStart: distanceFromStart,
                       bearing: point.bearing,
                       isStart: point.isStart,
                       isDestination: point.isDestination)
    }
}
