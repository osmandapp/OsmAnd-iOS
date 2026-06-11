//
//  SaveImportedGpxHelper.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

enum SaveImportedGpxHelper {
    static func processSavedFile(at path: String, gpxFile: GpxFile) {
        gpxFile.path = path
        let file = KFile(filePath: path)
        let db = GpxDbHelper.shared
        let dataItem = db.getItem(file: file) ?? GpxDataItem(file: file)

        dataItem.readGpxParams(gpxFile: gpxFile)
        let analysis = gpxFile.getAnalysis(
            fileTimestamp: file.lastModified(),
            fromDistance: nil,
            toDistance: nil,
            pointsAnalyzer: PlatformUtil.shared.getTrackPointsAnalyser()
        )
        dataItem.setAnalysis(analysis: analysis)
        dataItem.updateAppearance()

        if db.hasGpxDataItem(file: file) {
            db.updateDataItem(item: dataItem)
        } else {
            db.add(item: dataItem)
        }

        let trackItem = TrackItem(file: file)
        trackItem.dataItem = dataItem
        SharedLibSmartFolderHelper.shared.addTrackItemToSmartFolder(item: trackItem)
    }
}
