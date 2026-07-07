//
//  PlanRouteModels.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

enum PlanRouteMode {
    case newRoute
    case editTrack(fileName: String)

    var title: String {
        switch self {
        case .newRoute: localizedString("quick_action_new_route")
        case let .editTrack(fileName): fileName
        }
    }

    var isNewRoute: Bool {
        if case .newRoute = self { return true }
        return false
    }

    var isEditTrack: Bool {
        !isNewRoute
    }
}

enum PlanRouteTab: Int, CaseIterable {
    case poi
    case analyze
    case route

    static var `default`: PlanRouteTab {
        .route
    }

    var title: String {
        switch self {
        case .poi: localizedString("poi")
        case .analyze: localizedString("gpx_analyze")
        case .route: localizedString("layer_route")
        }
    }
}

enum PlanRouteMenuAction: CaseIterable {
    case saveAs
    case saveAsCopy
    case appendToExistingTrack
    case changeSegmentOrder
    case viewDirections
    case reverseRoute
    case navigation
    case clearAllPoints

    var title: String {
        switch self {
        case .saveAs: localizedString("plan_route_save_as")
        case .saveAsCopy: localizedString("save_as_copy")
        case .appendToExistingTrack: localizedString("plan_route_append_to_existing_track")
        case .changeSegmentOrder: localizedString("plan_route_change_segment_order")
        case .viewDirections: localizedString("plan_route_view_directions")
        case .reverseRoute: localizedString("reverse_route")
        case .navigation: localizedString("shared_string_navigation")
        case .clearAllPoints: localizedString("distance_measurement_clear_route")
        }
    }

    var icon: UIImage? {
        switch self {
        case .saveAs: .templateImageNamed("ic_custom_save_to_file")
        case .saveAsCopy: .templateImageNamed("ic_custom_save_as_new_file")
        case .appendToExistingTrack: .templateImageNamed("ic_custom_add_to_track")
        case .changeSegmentOrder: .templateImageNamed("ic_custom_list")
        case .viewDirections: .templateImageNamed("ic_custom_swap")
        case .reverseRoute: .templateImageNamed("ic_custom_swap")
        case .navigation: .templateImageNamed("ic_custom_navigation_outlined")
        case .clearAllPoints: .templateImageNamed("ic_custom_trash_outlined")
        }
    }

    var isDestructive: Bool {
        self == .clearAllPoints
    }

    static func actions(for mode: PlanRouteMode) -> [PlanRouteMenuAction] {
        allCases.filter { $0.isVisible(for: mode) }
    }

    func isVisible(for mode: PlanRouteMode) -> Bool {
        switch self {
        case .saveAsCopy: mode.isEditTrack
        default: true
        }
    }
}

struct PlanRouteInfo {
    static var empty: PlanRouteInfo {
        PlanRouteInfo(isNewRoute: true,
                      isStraightLine: false,
                      hasRoute: false,
                      totalDistance: 0,
                      duration: 0,
                      arrivalTime: nil,
                      uphill: 0,
                      downhill: 0,
                      mapCenterDistance: 0,
                      bearing: 0)
    }

    let isNewRoute: Bool
    let isStraightLine: Bool
    let hasRoute: Bool
    let totalDistance: Double
    let duration: TimeInterval
    let arrivalTime: Date?
    let uphill: Double
    let downhill: Double
    let mapCenterDistance: Double
    let bearing: Double

    var showsTime: Bool {
        !isStraightLine && duration > 0
    }
}

struct PlanRoutePoint {
    let index: Int
    let name: String
    let distanceFromPrevious: Double
    let bearing: Double
    let isStart: Bool
    let isDestination: Bool
}

struct PlanRouteProfileGroup {
    let appMode: OAApplicationMode?
    let distance: Double
    let lastPointIndex: Int
    let points: [PlanRoutePoint]
}

struct PlanRouteSegment {
    let index: Int
    let groups: [PlanRouteProfileGroup]
    let routed: Bool
    let multiMode: Bool
    let singleMode: OAApplicationMode?
    let distance: Double

    var pointIndexes: [Int] {
        groups.flatMap { $0.points.map { $0.index } }
    }
}

struct PlanRoutePoiGroup {
    let name: String
    let points: [PlanRoutePoiPoint]
}

struct PlanRoutePoiPoint {
    let name: String
    let subtitle: String
    let icon: UIImage
    let item: OAGpxWptItem
}

struct PlanRouteElevationData {
    let uphill: Double
    let downhill: Double
    let elevations: [Double]
}

struct PlanRouteAnalysisData {
    let uphill: Double
    let downhill: Double
    let altMin: Double?
    let altMax: Double?
    let avgSpeed: Double?
    let maxSpeed: Double?
    let timeInMotion: TimeInterval?
    let hasElevationData: Bool
    let gpxAnalysis: GpxTrackAnalysis?
    let gpxFile: GpxFile?
    let routeStatistics: [OARouteStatistics]
}

struct PlanRouteSegmentRoutingParams: Equatable {
    var useElevationData: Bool
    var considerTemporaryLimitations: Bool
}

enum SegmentRouteContext {
    case profileGroup(PlanRouteProfileGroup, segment: PlanRouteSegment)
    case wholeSegment(PlanRouteSegment)
    case wholeTrack

    var screenTitle: String {
        switch self {
        case let .profileGroup(_, segment), let .wholeSegment(segment):
            return String(format: localizedString("segments_count"), segment.index + 1)
        case .wholeTrack:
            return localizedString("route_between_points")
        }
    }

    var screenSubtitle: String? {
        switch self {
        case let .profileGroup(group, _):
            let modeName = group.appMode?.toHumanString() ?? localizedString("plan_route_straight_line")
            let distance = OAOsmAndFormatter.getFormattedDistance(Float(group.distance)) ?? ""
            return "\(modeName) • \(distance)"
        case let .wholeSegment(segment):
            guard !segment.multiMode, let mode = segment.singleMode else { return nil }
            let distance = OAOsmAndFormatter.getFormattedDistance(Float(segment.distance)) ?? ""
            return "\(mode.toHumanString() ?? "") • \(distance)"
        case .wholeTrack:
            return nil
        }
    }

    var recalculateSubtitle: String {
        switch self {
        case let .profileGroup(group, segment):
            let modeName = group.appMode?.toHumanString() ?? localizedString("plan_route_straight_line")
            let segmentTitle = String(format: localizedString("segments_count"), segment.index + 1)
            return String(format: localizedString("plan_route_section_recalculate_format"), modeName, segmentTitle)
        case let .wholeSegment(segment):
            let segmentTitle = String(format: localizedString("segments_count"), segment.index + 1)
            return String(format: localizedString("plan_route_segment_recalculate_format"), segmentTitle)
        case .wholeTrack:
            return localizedString("whole_track_descr")
        }
    }

    var currentMode: OAApplicationMode? {
        switch self {
        case let .profileGroup(group, _): return group.appMode
        case let .wholeSegment(segment): return segment.multiMode ? nil : segment.singleMode
        case .wholeTrack: return nil
        }
    }

    var applyPointIndex: Int {
        switch self {
        case let .profileGroup(group, _): return group.lastPointIndex
        case let .wholeSegment(segment): return segment.pointIndexes.last ?? 0
        case .wholeTrack: return 0
        }
    }

    var applyWholeRoute: Bool {
        switch self {
        case .profileGroup: return false
        case .wholeSegment: return true
        case .wholeTrack: return true
        }
    }

    var usesCloseButton: Bool {
        if case .wholeTrack = self { return true }
        return false
    }
}

protocol PlanRoutePoiDataSource: AnyObject {
    var poiGroups: [PlanRoutePoiGroup] { get }

    func openAddPoi(from presentingViewController: UIViewController)
    func addPoiGroup(_ name: String)
}

protocol PlanRouteAnalyzeDataSource: AnyObject {
    var routeInfo: PlanRouteInfo { get }
    var elevationData: PlanRouteElevationData? { get }
    var isCalculatingElevation: Bool { get }
    var isCalculatingRoute: Bool { get }
    var analysisData: PlanRouteAnalysisData? { get }

    func startElevationCalculation(useNearbyRoads: Bool)
    func cancelElevationCalculation()
}

protocol PlanRoutePointsDataSource: AnyObject {
    var routeInfo: PlanRouteInfo { get }
    var routeSegments: [PlanRouteSegment] { get }
    var defaultMode: OAApplicationMode? { get }
    var canStartNewSegment: Bool { get }
    var availableModes: [OAApplicationMode] { get }

    func addRoutePoint()
    func undo()
    func redo()
    func reverseRoute()
    func clearAllPoints()
    func moveRoutePoint(from: Int, to: Int)
    func moveSegment(from srcIdx: Int, to dstIdx: Int)
    func deleteRoutePoint(at index: Int)
    func deleteSegment(pointIndexes: [Int])
    func startNewSegment()
    func applyMode(_ mode: OAApplicationMode, pointIndex: Int, wholeRoute: Bool)
    func applyModeToContext(_ mode: OAApplicationMode?, context: SegmentRouteContext)
    func applyModeAllNext(fromPointIndex index: Int, mode: OAApplicationMode?)
    func sortDoorToDoor(pointIndexes: [Int])
    func saveSegment(pointIndexes: [Int])
    func selectRoutePoint(at index: Int)
    func showPointOptions(at index: Int)
    func addPointBefore(index: Int)
    func addPointAfter(index: Int)
    func trimBefore(index: Int)
    func trimAfter(index: Int)
    func routingParams(for mode: OAApplicationMode) -> PlanRouteSegmentRoutingParams
    func applyRoutingParams(_ params: PlanRouteSegmentRoutingParams, mode: OAApplicationMode)
    func refreshRoute(for mode: OAApplicationMode)
}

protocol PlanRouteSaveDataSource: AnyObject {
    func saveAs(fileName: String, folder: String?, showOnMap: Bool, onComplete: @escaping (Bool, String?) -> Void)
    func saveAsCopy(fileName: String, folder: String?, showOnMap: Bool, onComplete: @escaping (Bool, String?) -> Void)
    func appendToTrack(filePath: String, onComplete: @escaping (Bool) -> Void)
    func enterNavigation()
}

protocol PlanRouteDataProvider: PlanRoutePoiDataSource, PlanRouteAnalyzeDataSource, PlanRoutePointsDataSource, PlanRouteSaveDataSource {

    var mode: PlanRouteMode { get }
    var hasChanges: Bool { get }
    var hasPoints: Bool { get }
    var canUndo: Bool { get }
    var canRedo: Bool { get }
    var routeGpxFile: GpxFile? { get }
    var presenterViewController: UIViewController? { get set }
    var onDataChanged: (() -> Void)? { get set }
    var onRouteInfoChanged: (() -> Void)? { get set }
    var onChangeRouteTypeBefore: ((Int) -> Void)? { get set }
    var onChangeRouteTypeAfter: ((Int) -> Void)? { get set }

    func setCrosshairPosition(screenPoint: CGPoint)
    func dismissLayer()
}

protocol PlanRouteTabContent: AnyObject {
    var planRouteTab: PlanRouteTab { get }
    func reloadData()
}
