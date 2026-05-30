//
//  AstroGalleryLoader.swift
//  OsmAnd Maps
//
//  Ported from Android AstroGalleryLoader.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import CryptoKit
import OsmAndShared

final class AstroGalleryLoader {
    private var getAstroImagesTask: GetAstroImagesTask?
    private var requestWid: String?
    private var galleryItemsByWid: [String: [AbstractCard]] = [:]
    private let onStateChanged: (String, AstroGalleryState) -> Void
    private let cacheManager = AstroPhotoListCache()

    init(onStateChanged: @escaping (String, AstroGalleryState) -> Void) {
        self.onStateChanged = onStateChanged
    }

    func startLoading(_ wikidataId: String) {
        requestWid = wikidataId
        let rawKey = Self.buildRawKey(wikidataId: wikidataId)

        if let existingGalleryItems = galleryItemsByWid[wikidataId], !existingGalleryItems.isEmpty {
            publishReadyState(wikidataId: wikidataId, galleryItems: existingGalleryItems)
            return
        }

        guard AFNetworkReachabilityManagerWrapper.isReachable() else {
            cancelTaskOnly()
            loadFromCache(rawKey: rawKey, wikidataId: wikidataId)
            return
        }

        cancelTaskOnly()
        requestWid = wikidataId
        let networkResponseListener = AstroGalleryNetworkResponseListener { [weak self] response in
            self?.savePhotoListToCache(rawKey: rawKey, response: response)
        }
        let task = GetAstroImagesTask(wikidataId: wikidataId,
                                      getImageCardsListener: self,
                                      networkResponseListener: networkResponseListener)
        getAstroImagesTask = task
        task.execute()
    }

    func cancel() {
        requestWid = nil
        cancelTaskOnly()
    }

    private func cancelTaskOnly() {
        getAstroImagesTask?.cancel()
        getAstroImagesTask = nil
    }

    private func publishReadyState(wikidataId: String, galleryItems: [AbstractCard]) {
        onStateChanged(wikidataId, .ready(galleryItems))
    }

    private static func buildRawKey(wikidataId: String) -> String {
        "wikidataId=\(wikidataId)"
    }

    private func loadFromCache(rawKey: String, wikidataId: String) {
        guard cacheManager.exists(rawKey: rawKey) else {
            publishReadyState(wikidataId: wikidataId, galleryItems: [NoInternetCard()])
            return
        }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            let json = self?.cacheManager.load(rawKey: rawKey)
            let images = json.flatMap { cachedJson -> [OsmAndShared.WikiImage]? in
                guard !cachedJson.isEmpty else {
                    return nil
                }
                return WikiCoreHelper.shared.getAstroImagesFromJson(json: cachedJson)
            }

            DispatchQueue.main.async { [weak self] in
                guard let self, requestWid == wikidataId else {
                    return
                }
                let galleryItems = buildCards(images: images ?? [])
                if !galleryItems.isEmpty {
                    galleryItemsByWid[wikidataId] = galleryItems
                }
                publishReadyState(wikidataId: wikidataId, galleryItems: galleryItems)
            }
        }
    }

    private func savePhotoListToCache(rawKey: String, response: String?) {
        guard let response, !response.isEmpty else {
            return
        }
        DispatchQueue.global(qos: .utility).async { [cacheManager] in
            cacheManager.save(rawKey: rawKey, json: response)
        }
    }

    private func buildCards(images: [OsmAndShared.WikiImage]) -> [AbstractCard] {
        images.map { image in
            let wikiImage = WikiImage(wikiMediaTag: image.wikiMediaTag,
                                      imageName: image.imageName,
                                      imageStubUrl: image.imageStubUrl,
                                      imageHiResUrl: image.imageHiResUrl)
            wikiImage.mediaId = Int(image.getMediaId())
            wikiImage.metadata = Metadata(date: image.metadata.date,
                                          author: image.metadata.author,
                                          license: image.metadata.license,
                                          description: image.metadata.getDescription(preferredLanguage: Locale.current.languageCode))
            return WikiImageCard(wikiImage: wikiImage, type: "wikimedia-photo")
        }
    }
}

extension AstroGalleryLoader: GetAstroImagesTask.GetImageCardsListener {
    func onTaskStarted() {
    }

    func onFinish(wikidataId: String, images: [OsmAndShared.WikiImage]?) {
        getAstroImagesTask = nil
        guard requestWid == wikidataId else {
            return
        }
        let galleryItems = buildCards(images: images ?? [])
        if !galleryItems.isEmpty {
            galleryItemsByWid[wikidataId] = galleryItems
        }
        publishReadyState(wikidataId: wikidataId, galleryItems: galleryItems)
    }
}

private final class AstroGalleryNetworkResponseListener: NSObject, WikiCoreHelperNetworkResponseListener {
    private let onRawResponse: (String) -> Void

    init(onRawResponse: @escaping (String) -> Void) {
        self.onRawResponse = onRawResponse
    }

    func onGetRawResponse(response: String) {
        onRawResponse(response)
    }
}

private final class AstroPhotoListCache {
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
