//
//  PlanRoutePoiState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 28.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objc protocol PlanRoutePoiStateRestoring: AnyObject {
    func restorePoiStateSnapshot(_ state: PlanRoutePoiStateSnapshot)
}

@objcMembers
final class PlanRoutePoiStateSnapshot: NSObject {
    let gpxPoints: [WptPt]
    let gpxGroups: [String: GpxUtilities.PointsGroup]
    let hasDraftGpx: Bool
    let draftPoints: [WptPt]
    let draftGroups: [String: GpxUtilities.PointsGroup]

    init(gpxFile: GpxFile?, draftGpxFile: GpxFile?) {
        gpxPoints = Self.copyPoints(from: gpxFile)
        gpxGroups = Self.copyGroups(from: gpxFile)
        hasDraftGpx = draftGpxFile != nil
        draftPoints = Self.copyPoints(from: draftGpxFile)
        draftGroups = Self.copyGroups(from: draftGpxFile)
    }

    static func copyGroup(_ group: GpxUtilities.PointsGroup) -> GpxUtilities.PointsGroup {
        let copy = GpxUtilities.PointsGroup(name: group.name, iconName: group.iconName, backgroundType: group.backgroundType, color: group.color, hidden: group.hidden)
        let points = NSMutableArray()
        for point in group.points {
            points.add(WptPt(wptPt: point as! WptPt))
        }

        copy.points = points
        return copy
    }

    private static func copyPoints(from gpxFile: GpxFile?) -> [WptPt] {
        guard let gpxFile else { return [] }
        return gpxFile.getPointsList().map { WptPt(wptPt: $0) }
    }

    private static func copyGroups(from gpxFile: GpxFile?) -> [String: GpxUtilities.PointsGroup] {
        guard let gpxFile else { return [:] }
        var groups: [String: GpxUtilities.PointsGroup] = [:]
        for item in gpxFile.pointsGroups.allKeys {
            let key = item as! String
            let group = gpxFile.pointsGroups.object(forKey: key) as! GpxUtilities.PointsGroup
            groups[key] = copyGroup(group)
        }

        return groups
    }
}

@objcMembers
final class PlanRoutePoiStateCommand: OAMeasurementModeCommand {
    private let beforeState: PlanRoutePoiStateSnapshot?
    private let afterState: PlanRoutePoiStateSnapshot?
    private weak var restorer: PlanRoutePoiStateRestoring?

    init(layer: OAMeasurementToolLayer,
         restorer: PlanRoutePoiStateRestoring?,
         beforeState: PlanRoutePoiStateSnapshot?,
         afterState: PlanRoutePoiStateSnapshot?) {
        self.restorer = restorer
        self.beforeState = beforeState
        self.afterState = afterState
        super.init(layer: layer)
    }

    override func execute() -> Bool {
        restorer != nil && beforeState != nil && afterState != nil
    }

    override func undo() {
        guard let beforeState else { return }
        restorer?.restorePoiStateSnapshot(beforeState)
    }

    override func redo() {
        guard let afterState else { return }
        restorer?.restorePoiStateSnapshot(afterState)
    }
}
