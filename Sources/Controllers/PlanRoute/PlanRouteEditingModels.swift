//
//  PlanRouteEditingModels.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 28.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class PlanRoutePointData: NSObject {
    let globalIndex: Int
    let indexInSegment: Int
    let name: String
    let distanceFromPrevious: Double
    let bearing: Double
    let isStart: Bool
    let isDestination: Bool
    
    init(globalIndex: Int,
         indexInSegment: Int,
         name: String,
         distanceFromPrevious: Double,
         bearing: Double,
         isStart: Bool,
         isDestination: Bool) {
        self.globalIndex = globalIndex
        self.indexInSegment = indexInSegment
        self.name = name
        self.distanceFromPrevious = distanceFromPrevious
        self.bearing = bearing
        self.isStart = isStart
        self.isDestination = isDestination
    }
}

@objcMembers
final class PlanRouteGroupData: NSObject {
    let appMode: OAApplicationMode?
    let distance: Double
    let lastGlobalIndex: Int
    let points: [PlanRoutePointData]
    
    init(appMode: OAApplicationMode?, distance: Double, lastGlobalIndex: Int, points: [PlanRoutePointData]) {
        self.appMode = appMode
        self.distance = distance
        self.lastGlobalIndex = lastGlobalIndex
        self.points = points
    }
}

@objcMembers
final class PlanRouteSegmentData: NSObject {
    let index: Int
    let routed: Bool
    let multiMode: Bool
    let singleMode: OAApplicationMode?
    let distance: Double
    let groups: [PlanRouteGroupData]
    
    init(index: Int, routed: Bool, multiMode: Bool, singleMode: OAApplicationMode?, distance: Double, groups: [PlanRouteGroupData]) {
        self.index = index
        self.routed = routed
        self.multiMode = multiMode
        self.singleMode = singleMode
        self.distance = distance
        self.groups = groups
    }
}
