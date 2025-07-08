//
//  ClickableWayAsyncTask.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

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
        let waypoints = loader.loadHeightData(asWaypoints: Int64(clickableWay.getOsmId()), bbox31: clickableWay.getBbox())
        
        if let waypoints, waypoints.count > 0,
           let tracks = clickableWay.getGpxFile().tracks as? [Track],
           let segments = tracks.first?.segments as? [TrkSegment] {
            
            segments[0].points = waypoints
            return true
        }
        return false
    }
    
    private func openAsGpxFile(_ clickableWay: ClickableWay?) -> Bool {
        if let clickableWay = clickableWay {
            let gpxFile = clickableWay.getGpxFile()
            let analysis = gpxFile.getAnalysis(fileTimestamp: 0)
            let name = clickableWay.getGpxFileName()
            let safeFileName = clickableWay.getGpxFileName() + GPX_FILE_EXT
            let selectedPoint = clickableWay.getSelectedGpxPoint().getSelectedPoint()
            
            OAGPXUIHelper.saveAndOpenGpx(name, filepath: safeFileName, gpxFile: gpxFile, selectedPoint: selectedPoint, analysis: analysis, routeKey: nil, forceAdjustCentering: true)
            return true
        }
        return false
    }
} 
