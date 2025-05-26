//
//  TravelGpx.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

@objc(OATravelGpx)
@objcMembers
final class TravelGpx : TravelArticle {
    
    static let DISTANCE = "distance"
    static let DIFF_ELEVATION_UP = "diff_ele_up"
    static let DIFF_ELEVATION_DOWN = "diff_ele_down"
    static let MAX_ELEVATION = "max_ele"
    static let MIN_ELEVATION = "min_ele"
    static let AVERAGE_ELEVATION = "avg_ele"
    static let START_ELEVATION = "start_ele"
    static let ELE_GRAPH = "ele_graph"
    static let ROUTE_BBOX_RADIUS = "route_bbox_radius"
    static let ROUTE_SHORTLINK_TILES = "route_shortlink_tiles"
    static let ROUTE_SEGMENT_INDEX = "route_segment_index"
    static let USER = "user"
    static let ROUTE_TYPE = "route_type"
    static let ROUTE_ACTIVITY_TYPE = "route_activity_type"
    static let TRAVEL_MAP_TO_POI_TAG = "route_id"
    
    var user: String?
    var activityType: String?
    var totalDistance: Float = 0
    var diffElevationUp: Double = 0
    var diffElevationDown: Double = 0
    var maxElevation: Double = Double.nan
    var minElevation: Double = Double.nan
    var avgElevation: Double = 0
    
    var isSuperRoute: Bool = false
    
    private var amenitySubType: String?
    private var amenityRegionName: String?
    
    override init() {
        super.init()
    }
    
    init(amenity: OAPOI) {
        super.init()
        
        amenitySubType = amenity.subType
        amenityRegionName = amenity.regionName
        let enTitle = amenity.enName
        title = !amenity.name.isEmpty ? amenity.name : enTitle

        lat = amenity.latitude
        lon = amenity.longitude
        descr = amenity.getTagContent(DESCRIPTION_TAG)
        
        routeId = amenity.getTagContent(ROUTE_ID)
        user = amenity.getTagContent(TravelGpx.USER)
        activityType = amenity.getTagContent(TravelGpx.ROUTE_ACTIVITY_TYPE)
        ref = amenity.getRef()
        
        totalDistance = Float(amenity.getTagContent(TravelGpx.DISTANCE)) ?? 0
        diffElevationUp = Double(amenity.getTagContent(TravelGpx.DIFF_ELEVATION_UP)) ?? 0
        diffElevationDown = Double(amenity.getTagContent(TravelGpx.DIFF_ELEVATION_DOWN)) ?? 0
        maxElevation = Double(amenity.getTagContent(TravelGpx.MAX_ELEVATION)) ?? 0
        minElevation = Double(amenity.getTagContent(TravelGpx.MIN_ELEVATION)) ?? 0
        avgElevation = Double(amenity.getTagContent(TravelGpx.AVERAGE_ELEVATION)) ?? 0
        
        let helper = TravelObfHelper.shared
        
        if let radius: String = amenity.getTagContent(TravelGpx.ROUTE_BBOX_RADIUS) {
            OAUtilities.convertChar(toDist: String(radius[0]), firstLetter: String(helper.TRAVEL_GPX_CONVERT_FIRST_LETTER), firstDist: Int32(helper.TRAVEL_GPX_CONVERT_MULT_1), mult1: 0, mult2: Int32(helper.TRAVEL_GPX_CONVERT_MULT_2))
        } else if let routeId, !routeId.isEmpty {
            routeRadius = helper.ARTICLE_SEARCH_RADIUS
        }
        
        let shortLinkTiles = amenity.getTagContent(TravelGpx.ROUTE_SHORTLINK_TILES)
        if let shortLinkTiles {
            initShortLinkTiles(shortLinkTiles: shortLinkTiles)
        }
    
        if activityType == nil || activityType!.isEmpty {
            for key in amenity.getAdditionalInfoKeys() {
                if key.hasPrefix(Self.ROUTE_ACTIVITY_TYPE) {
                    activityType = amenity.getTagContent(key)
                }
            }
        }
        
        if (!amenity.getAdditionalInfo(ROUTE_MEMBERS_IDS).isEmpty) {
            isSuperRoute = true
        }
    }
    
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
                analysis.setHasData(tag: GpxUtilities.shared.POINT_ELEVATION, hasData: true)
            }
        }
        return analysis
    }
    
    override func getPointFilterString() -> String {
        ROUTE_TRACK_POINT
    }
}
