//
//  PhotoListCache.swift
//  OsmAnd Maps
//
//  Ported from Android PhotoCacheManager.java.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import CryptoKit

final class PhotoListCache {
    private static let cacheDirectoryName = "online_photos_list_cache"
    private static let maxCacheItems = 100

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    init() {
        let baseDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        cacheDirectory = (baseDirectory ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent(Self.cacheDirectoryName, isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }

    func save(rawKey: String, json: String) {
        guard let fileURL = fileURL(rawKey: rawKey) else {
            return
        }
        do {
            try json.write(to: fileURL, atomically: true, encoding: .utf8)
            cleanupIfNeeded()
        } catch {
            debugPrint("Error trying to save json photos list: \(error)")
        }
    }

    func load(rawKey: String) -> String? {
        guard let fileURL = fileURL(rawKey: rawKey), fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            debugPrint("Error trying to load cached json photos list: \(error)")
            return nil
        }
    }

    func exists(rawKey: String) -> Bool {
        guard let fileURL = fileURL(rawKey: rawKey) else {
            return false
        }
        return fileManager.fileExists(atPath: fileURL.path)
    }

    private func fileURL(rawKey: String) -> URL? {
        guard let fileName = hashKey(rawKey) else {
            return nil
        }
        return cacheDirectory.appendingPathComponent(fileName).appendingPathExtension("json")
    }

    private func cleanupIfNeeded() {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory,
                                                               includingPropertiesForKeys: [.contentModificationDateKey],
                                                               options: [.skipsHiddenFiles]) else {
            return
        }
        let jsonFiles = files.filter { $0.pathExtension == "json" }
        guard jsonFiles.count > Self.maxCacheItems else {
            return
        }
        let sortedFiles = jsonFiles.sorted {
            let firstDate = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let secondDate = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return firstDate < secondDate
        }
        sortedFiles.prefix(jsonFiles.count - Self.maxCacheItems).forEach {
            try? fileManager.removeItem(at: $0)
        }
    }

    private func hashKey(_ key: String) -> String? {
        guard let data = key.data(using: .utf8) else {
            return nil
        }
        return Insecure.MD5.hash(data: data).map { String(format: "%02x", Int($0)) }.joined()
    }
}
