//
//  AstroGalleryLoader.swift
//  OsmAnd Maps
//
//  Ported from Android AstroGalleryLoader.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

final class AstroGalleryLoader {
    private var getAstroImagesTask: GetAstroImagesTask?
    private var requestWid: String?
    private var galleryItemsByWid: [String: [AbstractCard]] = [:]
    private let onStateChanged: (String, AstroGalleryState) -> Void
    private let cacheManager = PhotoListCache()

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
        let networkResponseListener = WikiNetworkResponseListener { [weak self] response in
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
