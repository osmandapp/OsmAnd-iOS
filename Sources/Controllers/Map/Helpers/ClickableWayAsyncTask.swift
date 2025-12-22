//
//  ClickableWayAsyncTask.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// OsmAnd/src/net/osmand/plus/track/clickable/ClickableWayAsyncTask.java
// git revision a9b2a06728af2430efcc0bcf90b0c3568d239da1

import Foundation

@objcMembers
class ClickableWayAsyncTask: OABaseLoadAsyncTask {
    
    private var clickableWay: ClickableWay
    
    init(clickableWay: ClickableWay) {
        self.clickableWay = clickableWay
        super.init()
    }
    
    override func doInBackground() -> Any? {
        let result = readHeightData(clickableWay)
        return result ? clickableWay : nil
    }
    
    override func onPostExecute(result: Any?) {
        openAsGpxFile(result as? ClickableWay)
        super.onPostExecute(result: result)
    }
    
    private func readHeightData(_ clickableWay: ClickableWay) -> Bool {
        let loader = OAHeightDataLoader()
        loader.cancellable = self
        let waypoints = loader.loadHeightData(asWaypoints: Int64(clickableWay.osmId), bbox31: clickableWay.bbox)
        
        if !isCancelled(),
           let waypoints, waypoints.count > 0,
           let tracks = clickableWay.gpxFile.tracks as? [Track],
           let segments = tracks.first?.segments as? [TrkSegment] {
            segments[0].points = waypoints
            return true
        }
        return false
    }
    
    @discardableResult
    private func openAsGpxFile(_ clickableWay: ClickableWay?) -> Bool {
        if let clickableWay {
            let gpxFile = clickableWay.gpxFile
            let analysis = gpxFile.getAnalysis(fileTimestamp: 0)
            let name = clickableWay.getGpxFileName()
            let safeFileName = clickableWay.getGpxFileName() + GPX_FILE_EXT
            let selectedPoint = clickableWay.selectedGpxPoint.selectedPoint
            let forceAdjustCentering = !gpxFile.isEmpty()

            OAGPXUIHelper.saveAndOpenGpx(name, filepath: safeFileName, gpxFile: gpxFile, selectedPoint: selectedPoint,
                                         analysis: analysis, routeKey: nil, forceAdjustCentering: forceAdjustCentering)
            return true
        }
        return false
    }
} 
