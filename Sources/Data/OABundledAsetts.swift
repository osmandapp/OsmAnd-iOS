//
//  OABundledAsetts.swift
//  OsmAnd
//
//  Created by Victor Shcherb on 15.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//
import Foundation

@objc public class Asset: NSObject {
    @objc public let source: String
    @objc public let destination: String
    @objc public let mode: String?
    @objc public let version: NSNumber? // Use Int64 for timestamp

    init(source: String, destination: String, mode: String?, versionStr: String?) {
        self.source = source
        self.destination = destination
        self.mode = mode
        if let version = versionStr, let timestamp = Asset.parseDate(version) {
            self.version = NSNumber(value: timestamp) // Wrap timestamp in NSNumber
        } else {
            self.version = nil
        }
    }
    
    private static func parseDate(_ dateString: String) -> Int64? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        if let date = dateFormatter.date(from: dateString) {
            return Int64(date.timeIntervalSince1970)
        }
        return nil
    }
}

@objc public class BundledAssets: NSObject {
    @objc public static let shared = BundledAssets() // Singleton instance

    @objc public private(set) var assets: [String: Asset]?

    private override init() {
        super.init()

        if let filePath = Bundle.main.path(forResource: "bundled_assets", ofType: "json") {
            assets = BundledAssets.parse(fromJSONFile: filePath)
        } else {
            print("Error: bundled_assets.json not found in the main bundle.")
        }
    }

    private static func parse(fromJSONFile filePath: String) -> [String: Asset]? {
        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            print("Error loading JSON file.")
            return nil
        }
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
            guard let assetsArray = jsonDict?["assets"] as? [[String: Any]] else {
                print("Invalid JSON format.")
                return nil
            }
            var assetsMap = [String: Asset]()
            for assetDict in assetsArray {
                let iosEnabled = assetDict["ios"] as? Bool ?? true
                if !iosEnabled { continue } // Skip ONLY if "ios" is explicitly
                guard let source = assetDict["source"] as? String,
                      let destination = assetDict["destination"] as? String else {
                    print("Missing source or destination.")
                    continue
                }
                
                let mode = assetDict["mode"] as? String
                let version = assetDict["version"] as? String
                
                let asset = Asset(source: source, destination: destination, mode: mode, versionStr: version)
                assetsMap[destination] = asset // Group by destination
            }
            return assetsMap
        } catch {
            print("Error parsing JSON: \(error)")
            return nil
        }
    }
    
    @objc func migrateResourcesToDocumentsIfNeeded(dataPath:String, documentsPath:String, versionChanged: Bool) -> Bool {
        let movedRes = moveContentsOfDirectory(
            from: dataPath.appendingPathComponent(RESOURCES_DIR),
            to: documentsPath.appendingPathComponent(RESOURCES_DIR),
            folderName: RESOURCES_DIR, removeOriginalFile: true, versionChanged: versionChanged
        )
        let movedSqlite = moveContentsOfDirectory(
            from: dataPath.appendingPathComponent(MAP_CREATOR_DIR),
            to: documentsPath.appendingPathComponent(MAP_CREATOR_DIR),
            folderName: MAP_CREATOR_DIR, removeOriginalFile: true, versionChanged: versionChanged
        )
        if movedRes {
            migrateMapNames(at: documentsPath.appendingPathComponent(RESOURCES_DIR))
        }
        
        moveContentsOfDirectory(
            from: Bundle.main.path(forResource: COLOR_PALETTE_DIR, ofType: nil)!, // Force unwrap since it's assumed to exist
            to: documentsPath.appendingPathComponent(COLOR_PALETTE_DIR),
            folderName: COLOR_PALETTE_DIR, removeOriginalFile: false, versionChanged: versionChanged
        )
        moveContentsOfDirectory(
            from: Bundle.main.path(forResource: MODEL_3D_DIR, ofType: nil)!,
            to: documentsPath.appendingPathComponent(MODEL_3D_DIR),
            folderName: MODEL_3D_DIR, removeOriginalFile: false, versionChanged: versionChanged
        )
        if movedRes || movedSqlite {
            return true
        }
        return false
    }
    
    func migrateMapNames(at path: String) {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false // Use ObjCBool for bridging with Objective-C

        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else { return }

        guard let files = try? fileManager.contentsOfDirectory(atPath: path) else { return }

        for file in files {
            let oldPath = path.appendingPathComponent(file)
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: oldPath, isDirectory: &isDir), isDir.boolValue {
                migrateMapNames(at: oldPath) // Recursive call for subdirectories
            } else {
                let newPath = path.appendingPathComponent(generateCorrectFileName(file))
                if newPath != oldPath {
                    try? fileManager.moveItem(atPath: oldPath, toPath: newPath)
                }
            }
        }
    }
    
    @discardableResult
    func moveContentsOfDirectory(from src: String, to dest: String, folderName: String, removeOriginalFile: Bool, versionChanged: Bool) -> Bool {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: src) else { return false }

        if !fileManager.fileExists(atPath: dest) {
            try? fileManager.createDirectory(atPath: dest, withIntermediateDirectories: true, attributes: nil)
        }

        guard let files = try? fileManager.contentsOfDirectory(atPath: src) else { return false }

        var tryAgain = false
        for file in files {
            let destinationPath = dest.appendingPathComponent(file)
            if fileManager.fileExists(atPath: destinationPath) {
                if !versionChanged { continue }
                try? fileManager.removeItem(atPath: destinationPath)
            }
            do {
                if removeOriginalFile {
                    try fileManager.moveItem(atPath: src.appendingPathComponent(file), toPath: destinationPath)
                } else {
                    try fileManager.copyItem(atPath: src.appendingPathComponent(file), toPath: destinationPath)
                }
                if let assets = assets, let asset = assets["\(folderName)/\(file)"], let version = asset.version {
                    do {
                        let attributes = [FileAttributeKey.modificationDate: Date(timeIntervalSince1970: TimeInterval(version.intValue))]
                        try FileManager.default.setAttributes(attributes, ofItemAtPath: destinationPath)
                    } catch {
                        print("Error setting last modified date: \(error)")
                    }
                }
            } catch {
                print("Error copying \(file): \(error)")
                tryAgain = true
            }
        }

        if removeOriginalFile && !tryAgain {
            try? fileManager.removeItem(atPath: src)
        }

        return true
    }
    
    func generateCorrectFileName(_ path: String) -> String {
        var fileName = path.lastPathComponent() as String

        if fileName.hasSuffix(".map.obf") {
            fileName = OAUtilities.capitalizeFirstLetter(fileName.replacingOccurrences(of: ".map.obf", with: ".obf"))
        } else if fileName.hasSuffix(".obf") {
            fileName = OAUtilities.capitalizeFirstLetter(fileName)
        } else if fileName.hasSuffix(".sqlitedb") {
            if fileName.hasSuffix(".hillshade.sqlitedb") {
                fileName = fileName.replacingOccurrences(of: ".hillshade.sqlitedb", with: ".sqlitedb")
                fileName = fileName.replacingOccurrences(of: "_", with: " ")
                fileName = "Hillshade \(String(describing: OAUtilities.capitalizeFirstLetter(fileName)))"
            } else if fileName.hasSuffix(".slope.sqlitedb") {
                fileName = fileName.replacingOccurrences(of: ".slope.sqlitedb", with: ".sqlitedb")
                fileName = fileName.replacingOccurrences(of: "_", with: " ")
                fileName = "Slope \(String(describing: OAUtilities.capitalizeFirstLetter(fileName)))"
            }
        }

        return path.deletingLastPathComponent().appendingPathComponent(fileName)
    }
}
