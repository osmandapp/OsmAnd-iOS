//
//  OAClickableWayAsyncTask.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class OAClickableWayAsyncTask: OABaseLoadAsyncTask {
    
    private var clickableWay: OAClickableWay
    
    init(clickableWay: OAClickableWay) {
        self.clickableWay = clickableWay
        super.init()
    }
    
    override func doInBackground() -> Any? {
        let result = readHeightData(clickableWay)
        return result ? clickableWay : nil
    }
    
    override func onPostExecute(result: Any?) {
        openAsGpxFile(result as? OAClickableWay)
        super.onPostExecute(result: result)
    }
    
    private func readHeightData(_ clickableWay: OAClickableWay) -> Bool {
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
    
    private func openAsGpxFile(_ clickableWay: OAClickableWay?) -> Bool {
        if let clickableWay = clickableWay {
            let gpxFile = clickableWay.getGpxFile()
            let analysis = gpxFile.getAnalysis(fileTimestamp: 0)
            let name = clickableWay.getGpxFileName()
            let safeFileName = clickableWay.getGpxFileName() + GPX_FILE_EXT
            let selectedPoint = clickableWay.getSelectedGpxPoint().getSelectedPoint()
            
            OAGPXUIHelper.saveAndOpenGpx(name, filepath: safeFileName, gpxFile: gpxFile, selectedPoint: selectedPoint, analysis: analysis, routeKey: nil)
            return true
        }
        return false
    }
} 
