//
//  SaveGpxAsyncTask.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

protocol SaveImportedGpxListener: AnyObject {
    func onGpxSavingStarted()
    func onGpxSaved(error: String?, savedPath: String?)
    func onGpxSavingFinished(warning: [String])
}

private struct SaveGpxTaskResult {
    let savedPath: String?
    let writeError: String?
    let warning: String?

    static func failure(message: String, savedPath: String? = nil) -> SaveGpxTaskResult {
        SaveGpxTaskResult(savedPath: savedPath, writeError: message, warning: message)
    }

    static func success(savedPath: String) -> SaveGpxTaskResult {
        SaveGpxTaskResult(savedPath: savedPath, writeError: nil, warning: nil)
    }
}

final class SaveGpxAsyncTask: OAAsyncTask {

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

    private var fileManager: FileManager { .default }
    
    // MARK: - Init

    init(gpxFile: GpxFile,
         destinationDir: String,
         fileName: String,
         overwrite: Bool,
         importURL: URL?,
         listener: SaveImportedGpxListener?) {
        self.gpxFile = gpxFile
        self.destinationDir = destinationDir
        self.fileName = fileName
        self.overwrite = overwrite
        self.importURL = importURL
        self.listener = listener
        super.init()
    }
    
    // MARK: - Static

    static func plannedDestinationPath(destinationDir: String, fileName: String) -> String {
        var name = SaveImportedGpxHelper.sanitizedFileName(from: fileName, stripArchiveExtensions: true)

        return (destinationDir as NSString).appendingPathComponent(name)
    }
    
    // MARK: - Override

    override func onPreExecute() {
        listener?.onGpxSavingStarted()
    }

    override func doInBackground() -> Any? {
        guard !gpxFile.isEmpty() else {
            return SaveGpxTaskResult.failure(message: localizedString("error_reading_gpx"))
        }

        if let directoryError = validateDestinationDirectory() {
            return SaveGpxTaskResult.failure(message: directoryError)
        }

        let destinationPath = resolveDestinationPath()
        if let writeError = writeGpx(to: destinationPath) {
            return SaveGpxTaskResult.failure(message: writeError, savedPath: destinationPath)
        }

        SaveImportedGpxHelper.processSavedFile(at: destinationPath, gpxFile: gpxFile)
        return SaveGpxTaskResult.success(savedPath: destinationPath)
    }

    override func onPostExecute(result: Any?) {
        guard let result = result as? SaveGpxTaskResult else {
            listener?.onGpxSaved(error: localizedString("error_reading_gpx"), savedPath: nil)
            listener?.onGpxSavingFinished(warning: [localizedString("error_reading_gpx")])
            return
        }

        listener?.onGpxSaved(error: result.writeError, savedPath: result.savedPath)
        listener?.onGpxSavingFinished(warning: [result.warning].compactMap { $0 })
    }

    // MARK: - Destination

    private func validateDestinationDirectory() -> String? {
        do {
            try fileManager.createDirectory(atPath: destinationDir, withIntermediateDirectories: true)
        } catch {
            return localizedString("import_failed")
        }

        guard fileManager.isWritableFile(atPath: destinationDir) else {
            return localizedString("import_failed")
        }
        return nil
    }

    private func resolveDestinationPath() -> String {
        var name = SaveImportedGpxHelper.sanitizedFileName(from: fileName, stripArchiveExtensions: true)

        if name.isEmpty {
            let point = gpxFile.findPointToShow()
            let timestamp = point?.time ?? Int64(Date().timeIntervalSince1970 * 1000)
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
            name = "import_\(Self.importDateFormat.string(from: date))\(SaveImportedGpxHelper.gpxExtension)"
        }

        var destinationPath = (destinationDir as NSString).appendingPathComponent(name)
        guard !overwrite else { return destinationPath }

        while fileManager.fileExists(atPath: destinationPath) {
            name = OAUtilities.createNewFileName(name)
            destinationPath = (destinationDir as NSString).appendingPathComponent(name)
        }
        return destinationPath
    }

    // MARK: - Writing

    private func writeGpx(to destinationPath: String) -> String? {
        if overwrite, fileManager.fileExists(atPath: destinationPath) {
            try? fileManager.removeItem(atPath: destinationPath)
            if let item = OAGPXDatabase.sharedDb().getGPXItem(destinationPath) {
                OAGPXDatabase.sharedDb().removeGpxItem(item, withLocalRemove: false)
            }
        }

        if !gpxFile.path.isEmpty, isTempFileToMove(gpxFile.path) {
            return moveTempFile(from: gpxFile.path, to: destinationPath)
        }

        if let importURL, fileManager.fileExists(atPath: importURL.path) {
            return copyImportedFile(from: importURL.path, to: destinationPath)
        }

        return writeGpxFile(to: destinationPath)
    }

    private func moveTempFile(from sourcePath: String, to destinationPath: String) -> String? {
        do {
            try fileManager.moveItem(atPath: sourcePath, toPath: destinationPath)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func copyImportedFile(from sourcePath: String, to destinationPath: String) -> String? {
        do {
            try fileManager.copyItem(at: URL(fileURLWithPath: sourcePath), to: URL(fileURLWithPath: destinationPath))
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func writeGpxFile(to destinationPath: String) -> String? {
        let file = KFile(filePath: destinationPath)
        if let exception = GpxUtilities.shared.writeGpxFile(file: file, gpxFile: gpxFile) {
            return exception.message ?? localizedString("error_reading_gpx")
        }
        return nil
    }

    private func isTempFileToMove(_ path: String) -> Bool {
        guard let gpxPath = OsmAndApp.swiftInstance()?.gpxPath else { return false }
        let tempDir = (gpxPath as NSString).appendingPathComponent("temp")
        return (path as NSString).deletingLastPathComponent == tempDir
    }
}
