//
//  PlanRouteModels.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

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

    var title: String {
        switch self {
        case .poi: localizedString("poi")
        case .analyze: localizedString("gpx_analyze")
        case .route: localizedString("layer_route")
        }
    }

    static var `default`: PlanRouteTab {
        .route
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
        case .viewDirections: .templateImageNamed("ic_custom_route_points")
        case .reverseRoute: .templateImageNamed("ic_custom_change_object_position")
        case .navigation: .templateImageNamed("ic_custom_navigation_outlined")
        case .clearAllPoints: .templateImageNamed("ic_custom_trash_outlined")
        }
    }

    var isDestructive: Bool {
        self == .clearAllPoints
    }

    func isVisible(for mode: PlanRouteMode) -> Bool {
        switch self {
        case .saveAsCopy: mode.isEditTrack
        default: true
        }
    }

    static func actions(for mode: PlanRouteMode) -> [PlanRouteMenuAction] {
        allCases.filter { $0.isVisible(for: mode) }
    }
}

struct PlanRouteInfo {
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
        !isNewRoute && !isStraightLine && duration > 0
    }

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

struct PlanRouteElevationData {
    let uphill: Double
    let downhill: Double
    let elevations: [Double]
}

protocol PlanRoutePoiDataSource: AnyObject {
    var poiPoints: [PlanRoutePoint] { get }
}

protocol PlanRouteAnalyzeDataSource: AnyObject {
    var routeInfo: PlanRouteInfo { get }
    var elevationData: PlanRouteElevationData? { get }
}

protocol PlanRoutePointsDataSource: AnyObject {
    var routeInfo: PlanRouteInfo { get }
    var routeSegments: [PlanRouteSegment] { get }
    var canStartNewSegment: Bool { get }
    var availableModes: [OAApplicationMode] { get }

    func addRoutePoint()
    func deleteRoutePoint(at index: Int)
    func deleteSegment(pointIndexes: [Int])
    func startNewSegment()
    func applyMode(_ mode: OAApplicationMode, pointIndex: Int, wholeRoute: Bool)
    func sortDoorToDoor(pointIndexes: [Int])
    func saveSegment(pointIndexes: [Int])
    func selectRoutePoint(at index: Int)
}

protocol PlanRouteDataProvider: PlanRoutePoiDataSource, PlanRouteAnalyzeDataSource, PlanRoutePointsDataSource {
    var mode: PlanRouteMode { get }
    var hasChanges: Bool { get }
    var canUndo: Bool { get }
    var canRedo: Bool { get }
}

protocol PlanRouteTabContent: AnyObject {
    var planRouteTab: PlanRouteTab { get }
    func reloadData()
}
