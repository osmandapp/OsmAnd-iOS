//
//  SaveGpxTask.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

protocol SaveImportedGpxListener: AnyObject {
    func gpxSavingStarted()
    func gpxSaved(error: String?, savedPath: String?)
    func gpxSavingFinished(warning: String?)
}

private struct SaveGpxTaskResult {
    let savedPath: String?
    let writeError: String?
    let warning: String?
}

final class SaveGpxTask: OAAsyncTask {

    private static let gpxExtension = ".gpx"
    private static let importDateFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH-mm_EEE"
        return formatter
    }()

    private let gpxFile: GpxFile
    private let destinationDir: String
    private let fileName: String
    private let overwrite: Bool
    private let importURL: URL?
    private weak var listener: SaveImportedGpxListener?
    
    private var fm: FileManager { FileManager.default }

    init(gpxFile: GpxFile, destinationDir: String, fileName: String,
         overwrite: Bool, importURL: URL?, listener: SaveImportedGpxListener?) {
        
        self.gpxFile = gpxFile
        self.destinationDir = destinationDir
        self.fileName = fileName
        self.overwrite = overwrite
        self.importURL = importURL
        self.listener = listener
        super.init()
    }

    override func onPreExecute() {
        listener?.gpxSavingStarted()
    }

    override func doInBackground() -> Any? {
        if gpxFile.isEmpty() {
            return SaveGpxTaskResult(
                savedPath: nil,
                writeError: localizedString("error_reading_gpx"),
                warning: localizedString("error_reading_gpx")
            )
        }

        let fm = FileManager.default
        do {
            try fm.createDirectory(atPath: destinationDir, withIntermediateDirectories: true)
        } catch {
            return SaveGpxTaskResult(
                savedPath: nil,
                writeError: localizedString("sd_dir_not_accessible"),
                warning: localizedString("sd_dir_not_accessible")
            )
        }

        guard fm.isWritableFile(atPath: destinationDir) else {
            return SaveGpxTaskResult(
                savedPath: nil,
                writeError: localizedString("sd_dir_not_accessible"),
                warning: localizedString("sd_dir_not_accessible")
            )
        }

        let destPath = resolveDestinationPath()
        let writeError = saveFile(to: destPath)

        if let writeError {
            return SaveGpxTaskResult(
                savedPath: destPath,
                writeError: writeError,
                warning: localizedString("error_reading_gpx")
            )
        }

        processSavedFile(at: destPath)
        return SaveGpxTaskResult(savedPath: destPath, writeError: nil, warning: nil)
    }

    override func onPostExecute(result: Any?) {
        guard let result = result as? SaveGpxTaskResult else {
            listener?.gpxSaved(error: localizedString("error_reading_gpx"), savedPath: nil)
            listener?.gpxSavingFinished(warning: localizedString("error_reading_gpx"))
            return
        }

        listener?.gpxSaved(error: result.writeError, savedPath: result.savedPath)
        listener?.gpxSavingFinished(warning: result.warning)
    }

    // MARK: - Android SaveGpxAsyncTask parity

    private func resolveDestinationPath() -> String {
        var name = normalizedFileName(fileName)

        if name.isEmpty {
            let pt = gpxFile.findPointToShow()
            let time = pt?.time ?? Int64(Date().timeIntervalSince1970 * 1000)
            let date = Date(timeIntervalSince1970: TimeInterval(time) / 1000)
            name = "import_\(Self.importDateFormat.string(from: date))\(Self.gpxExtension)"
        }

        var destPath = (destinationDir as NSString).appendingPathComponent(name)

        if !overwrite {
            while fm.fileExists(atPath: destPath) {
                name = OAUtilities.createNewFileName(name)
                destPath = (destinationDir as NSString).appendingPathComponent(name)
            }
        }

        return destPath
    }

    private func normalizedFileName(_ raw: String) -> String {
        var name = raw
        let lower = name.lowercased()
        if lower.hasSuffix(".kml") { name = String(name.dropLast(4)) }
        else if lower.hasSuffix(".kmz") { name = String(name.dropLast(4)) }
        else if lower.hasSuffix(".zip") { name = String(name.dropLast(4)) }

        if !name.lowercased().hasSuffix(Self.gpxExtension) {
            name += Self.gpxExtension
        }
        return name
    }

    private func saveFile(to destPath: String) -> String? {
        let fm = FileManager.default

        if overwrite, fm.fileExists(atPath: destPath) {
            try? fm.removeItem(atPath: destPath)
            if let item = OAGPXDatabase.sharedDb().getGPXItem(destPath) {
                OAGPXDatabase.sharedDb().removeGpxItem(item, withLocalRemove: false)
            }
        }

        if !gpxFile.path.isEmpty, isTempFileToMove(gpxFile.path) {
            do {
                try fm.moveItem(atPath: gpxFile.path, toPath: destPath)
                return nil
            } catch {
                return error.localizedDescription
            }
        }

        // 2) copy из importURL (document picker / inbox)
        if let importURL, fm.fileExists(atPath: importURL.path) {
            do {
                try fm.copyItem(at: URL(fileURLWithPath: importURL.path), to: URL(fileURLWithPath: destPath))
                return nil
            } catch {
                return error.localizedDescription
            }
        }

        // 3) write GPX
        let file = KFile(filePath: destPath)
        if let exception = GpxUtilities.shared.writeGpxFile(file: file, gpxFile: gpxFile) {
            return exception.message ?? localizedString("error_reading_gpx")
        }
        return nil
    }
    
    private func processSavedFile(at path: String) {
        SaveImportedGpxHelper.processSavedFile(at: path, gpxFile: gpxFile)
    }

    private func isTempFileToMove(_ path: String) -> Bool {
        guard let gpxPath = OsmAndApp.swiftInstance()?.gpxPath else { return false }
        let tempDir = (gpxPath as NSString).appendingPathComponent("temp")
        let parent = (path as NSString).deletingLastPathComponent
        return parent == tempDir
    }
    
    // MARK: - Static helpers
    
    static func plannedDestinationPath(destinationDir: String, fileName: String) -> String {
        var name = rawNormalizedFileName(fileName)
        if name.isEmpty {
            name = "import\(gpxExtension)"
        }
        return (destinationDir as NSString).appendingPathComponent(name)
    }

    private static func rawNormalizedFileName(_ raw: String) -> String {
        var name = raw
        let lower = name.lowercased()
        if lower.hasSuffix(".kml") || lower.hasSuffix(".kmz") || lower.hasSuffix(".zip") {
            name = String(name.dropLast(4))
        }
        if !name.lowercased().hasSuffix(gpxExtension) {
            name += gpxExtension
        }
        return name
    }
}
