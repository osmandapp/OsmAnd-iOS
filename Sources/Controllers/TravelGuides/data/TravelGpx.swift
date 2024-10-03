//
//  TravelGpx.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OATravelGpx)
@objcMembers
final class TravelGpx : TravelArticle {
    
    static let DISTANCE = "distance"
    static let DIFF_ELEVATION_UP = "diff_ele_up"
    static let DIFF_ELEVATION_DOWN = "diff_ele_down"
    static let MAX_ELEVATION = "max_ele"
    static let MIN_ELEVATION = "min_ele"
    static let AVERAGE_ELEVATION = "avg_ele"
    static let ROUTE_RADIUS = "route_radius"
    static let USER = "user"
    static let ACTIVITY_TYPE = "route_activity_type"
    
    var user: String?
    var activityType: String?
    var totalDistance: Float = 0
    var diffElevationUp: Double = 0
    var diffElevationDown: Double = 0
    var maxElevation: Double = Double.nan
    var minElevation: Double = Double.nan
    var avgElevation: Double = 0
    
    override func getAnalysis() -> GpxTrackAnalysis? {
        var analysis = GpxTrackAnalysis()
        if gpxFile != nil && gpxFile!.hasAltitude() {
            analysis = gpxFile!.getAnalysis(0)
        } else {
            analysis.diffElevationDown = diffElevationDown
            analysis.diffElevationUp = diffElevationUp
            analysis.maxElevation = maxElevation
            analysis.minElevation = minElevation
            analysis.totalDistance = totalDistance
            analysis.totalDistanceWithoutGaps = totalDistance
            analysis.avgElevation = avgElevation
            if maxElevation != Double.nan && minElevation != Double.nan {
                analysis.hasElevationData = true
            }
        }
        return analysis
    }
    
    override func getPointFilterString() -> String {
        ROUTE_TRACK_POINT
    }
}
