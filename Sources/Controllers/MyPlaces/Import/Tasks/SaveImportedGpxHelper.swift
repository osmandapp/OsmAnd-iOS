//
//  SaveImportedGpxHelper.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

enum SaveImportedGpxHelper {
    static func processSavedFile(at path: String, gpxFile: GpxFile) {
        gpxFile.path = path

        let file = KFile(filePath: path)
        let dataItem = makeOrLoadDataItem(for: file, gpxFile: gpxFile)
        persist(dataItem, file: file)
        registerInSmartFolder(file: file, dataItem: dataItem)
    }

    private static func makeOrLoadDataItem(for file: KFile, gpxFile: GpxFile) -> GpxDataItem {
        let dataItem = GpxDbHelper.shared.getItem(file: file) ?? GpxDataItem(file: file)
        dataItem.readGpxParams(gpxFile: gpxFile)

        let analysis = gpxFile.getAnalysis(
            fileTimestamp: file.lastModified(),
            fromDistance: nil,
            toDistance: nil,
            pointsAnalyzer: PlatformUtil.shared.getTrackPointsAnalyser()
        )
        dataItem.setAnalysis(analysis: analysis)
        dataItem.updateAppearance()
        return dataItem
    }

    private static func persist(_ dataItem: GpxDataItem, file: KFile) {
        let db = GpxDbHelper.shared
        if db.hasGpxDataItem(file: file) {
            db.updateDataItem(item: dataItem)
        } else {
            db.add(item: dataItem)
        }
    }

    private static func registerInSmartFolder(file: KFile, dataItem: GpxDataItem) {
        let trackItem = TrackItem(file: file)
        trackItem.dataItem = dataItem
        SharedLibSmartFolderHelper.shared.addTrackItemToSmartFolder(item: trackItem)
    }
}
