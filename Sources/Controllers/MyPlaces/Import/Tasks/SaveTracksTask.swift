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
    var warnings: [String] { trackResults.compactMap(\.error) }
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
        listener?.onGpxSavingStarted()
    }

    override func doInBackground() -> Any? {
        let fileManager = FileManager.default

        if let destinationError = validateDestinationDirectory(using: fileManager) {
            return SaveTracksTaskResult(trackResults: [
                SavedTrackResult(error: destinationError, savedPath: nil)
            ])
        }

        var results: [SavedTrackResult] = []
        for trackItem in items {
            if isCancelled() { break }
            results.append(saveTrackItem(trackItem, fileManager: fileManager))
        }

        return SaveTracksTaskResult(trackResults: results)
    }

    override func onPostExecute(result: Any?) {
        guard let result = result as? SaveTracksTaskResult else {
            listener?.onGpxSaved(error: localizedString("error_reading_gpx"), savedPath: nil)
            listener?.onGpxSavingFinished(warning: [localizedString("error_reading_gpx")])
            return
        }

        for trackResult in result.trackResults {
            listener?.onGpxSaved(error: trackResult.error, savedPath: trackResult.savedPath)
        }
        listener?.onGpxSavingFinished(warning: result.warnings)
    }

    // MARK: - Saving

    private func validateDestinationDirectory(using fileManager: FileManager) -> String? {
        do {
            try fileManager.createDirectory(atPath: destinationDir, withIntermediateDirectories: true)
        } catch {
            return localizedString("sd_dir_not_accessible")
        }

        guard fileManager.isWritableFile(atPath: destinationDir) else {
            return localizedString("sd_dir_not_accessible")
        }
        return nil
    }

    private func saveTrackItem(_ trackItem: ImportTrackItem, fileManager: FileManager) -> SavedTrackResult {
        let gpxToSave = trackItem.selectedGpxFile
        gpxToSave.addPoints(collection: trackItem.selectedPoints)

        let destinationPath = uniqueDestinationPath(for: trackItem.name, fileManager: fileManager)
        let file = KFile(filePath: destinationPath)

        if let exception = GpxUtilities.shared.writeGpxFile(file: file, gpxFile: gpxToSave) {
            let error = exception.message ?? localizedString("error_reading_gpx")
            return SavedTrackResult(error: error, savedPath: nil)
        }

        SaveImportedGpxHelper.processSavedFile(at: destinationPath, gpxFile: gpxToSave)
        return SavedTrackResult(error: nil, savedPath: destinationPath)
    }

    private func uniqueDestinationPath(for rawName: String, fileManager: FileManager) -> String {
        var fileName = rawName
        if !fileName.lowercased().hasSuffix(Self.gpxExtension) {
            fileName += Self.gpxExtension
        }

        var destinationPath = (destinationDir as NSString).appendingPathComponent(fileName)
        while fileManager.fileExists(atPath: destinationPath) {
            fileName = OAUtilities.createNewFileName(fileName)
            destinationPath = (destinationDir as NSString).appendingPathComponent(fileName)
        }
        return destinationPath
    }
}
