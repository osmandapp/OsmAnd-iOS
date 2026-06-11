//
//  SaveTracksTask.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

private struct SavedTrackResult {
    let error: String?
    let savedPath: String?
}

private struct SaveTracksTaskResult {
    let trackResults: [SavedTrackResult]
    var firstWarning: String? { trackResults.compactMap(\.error).first }
}

final class SaveTracksTask: OAAsyncTask {

    private static let gpxExtension = ".gpx"

    private let items: [ImportTrackItem]
    private let destinationDir: String
    private weak var listener: SaveImportedGpxListener?

    init(items: [ImportTrackItem], destinationDir: String, listener: SaveImportedGpxListener?) {
        self.items = items
        self.destinationDir = destinationDir
        self.listener = listener
        super.init()
    }

    override func onPreExecute() {
        listener?.gpxSavingStarted()
    }

    override func doInBackground() -> Any? {
        let fm = FileManager.default

        do {
            try fm.createDirectory(atPath: destinationDir, withIntermediateDirectories: true)
        } catch {
            return SaveTracksTaskResult(trackResults: [
                SavedTrackResult(error: localizedString("sd_dir_not_accessible"), savedPath: nil)
            ])
        }

        guard fm.isWritableFile(atPath: destinationDir) else {
            return SaveTracksTaskResult(trackResults: [
                SavedTrackResult(error: localizedString("sd_dir_not_accessible"), savedPath: nil)
            ])
        }

        var results: [SavedTrackResult] = []

        for trackItem in items {
            if isCancelled() { break }

            let gpxToSave = trackItem.gpxFile
            gpxToSave.addPoints(collection: trackItem.selectedPoints)

            var name = trackItem.name
            if !name.lowercased().hasSuffix(Self.gpxExtension) {
                name += Self.gpxExtension
            }

            var destPath = (destinationDir as NSString).appendingPathComponent(name)
            while fm.fileExists(atPath: destPath) {
                name = OAUtilities.createNewFileName(name)
                destPath = (destinationDir as NSString).appendingPathComponent(name)
            }

            let file = KFile(filePath: destPath)
            if let exception = GpxUtilities.shared.writeGpxFile(file: file, gpxFile: gpxToSave) {
                let error = exception.message ?? localizedString("error_reading_gpx")
                results.append(SavedTrackResult(error: error, savedPath: nil))
            } else {
                SaveImportedGpxHelper.processSavedFile(at: destPath, gpxFile: gpxToSave)
                results.append(SavedTrackResult(error: nil, savedPath: destPath))
            }
        }

        return SaveTracksTaskResult(trackResults: results)
    }

    override func onPostExecute(result: Any?) {
        guard let result = result as? SaveTracksTaskResult else {
            listener?.gpxSaved(error: localizedString("error_reading_gpx"), savedPath: nil)
            listener?.gpxSavingFinished(warning: localizedString("error_reading_gpx"))
            return
        }

        for trackResult in result.trackResults {
            listener?.gpxSaved(error: trackResult.error, savedPath: trackResult.savedPath)
        }
        listener?.gpxSavingFinished(warning: result.firstWarning)
    }
}
