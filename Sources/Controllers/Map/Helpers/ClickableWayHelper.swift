//
//  ClickableWayHelper.swift
//  OsmAnd
//
//  Created by Max Kojin on 25/12/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

@objcMembers
final class ClickableWayHelper: NSObject {
    
    @discardableResult
    static func openAsGpxFile(_ clickableWay: ClickableWay?) -> Bool {
        Self.openAsGpxFile(clickableWay, adjustMapPosition: false)
    }
    
    @discardableResult
    static func openAsGpxFile(_ clickableWay: ClickableWay?, adjustMapPosition: Bool) -> Bool {
        if let clickableWay {
            let gpxFile = clickableWay.gpxFile
            let analysis = gpxFile.getAnalysis(fileTimestamp: 0)
            let name = clickableWay.getGpxFileName()
            let safeFileName = clickableWay.getGpxFileName() + GPX_FILE_EXT
            let selectedPoint = clickableWay.selectedGpxPoint.selectedPoint

            OAGPXUIHelper.saveAndOpenGpx(name, filepath: safeFileName, gpxFile: gpxFile, selectedPoint: selectedPoint, analysis: analysis, routeKey: nil, forceAdjustCentering: adjustMapPosition)
            return true
        }
        return false
    }

    static func readHeightData(_ clickableWay: ClickableWay, canceller: OACancellable?) -> Bool {
        let loader = OAHeightDataLoader()
        loader.cancellable = canceller
        let waypoints = loader.loadHeightData(asWaypoints: Int64(clickableWay.osmId), bbox31: clickableWay.bbox)
        
        if (canceller == nil || !(canceller?.isCancelled() ?? true)),
           let waypoints, waypoints.count > 0,
           let tracks = clickableWay.gpxFile.tracks as? [Track],
           let segments = tracks.first?.segments as? [TrkSegment] {
            
            segments[0].points = waypoints
            return true
        }
        return false
    }
    
    static func openClickableWayAmenity(amenity: OAPOI, adjustMapPosition: Bool) {
        if let detailedObject = OAAmenitySearcher.sharedInstance().searchDetailedObject(amenity) {
            let helper = OAClickableWayHelper()
            let clickableWay = helper.loadClickableWay(detailedObject.syntheticAmenity)
            readHeightData(clickableWay, canceller: nil)
            openAsGpxFile(clickableWay, adjustMapPosition: adjustMapPosition)
        }
    }    
}
