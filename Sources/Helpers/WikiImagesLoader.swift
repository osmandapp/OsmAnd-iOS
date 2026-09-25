//
//  WikiImagesLoader.swift
//  OsmAnd Maps
//
//  Ported from Android OnlinePhotosDelegate.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

@objcMembers
final class WikiImagesLoader: NSObject {
    private let cache = AstroPhotoListCache()
    private var activeToken: UUID?

    private static func cachedImages(_ cache: AstroPhotoListCache,
                                     rawKey: String,
                                     wikiTagData: WikiHelper.WikiTagData) -> [OsmAndShared.WikiImage] {
        guard let json = cache.load(rawKey: rawKey), !json.isEmpty else {
            return []
        }
        return WikiCoreHelper.shared.getImagesFromJson(json: json, wikiImages: wikiTagData.wikiImages)
    }

    private static func buildRawKey(_ wikiTagData: WikiHelper.WikiTagData) -> String {
        var params = [String]()
        if let wikidataId = wikiTagData.wikidataId, !wikidataId.isEmpty {
            params.append("article=\(wikidataId)")
        }
        if let wikiCategory = wikiTagData.wikiCategory, !wikiCategory.isEmpty {
            params.append("category=\(wikiCategory)")
        }
        if let wikiTitle = wikiTagData.wikiTitle, !wikiTitle.isEmpty {
            params.append("wiki=\(wikiTitle)")
        }
        if let file = (wikiTagData.wikiImages.firstObject as? OsmAndShared.WikiImage)?.wikiMediaTag {
            params.append("file=\(file)")
        }
        return params.joined(separator: "&")
    }

    private static func buildCards(_ images: [OsmAndShared.WikiImage]) -> [AbstractCard] {
        images.map { WikiImageCard(wikiImage: WikiImage($0), type: "wikimedia-photo") }
    }

    func load(tags: [String: String],
              onComplete: @escaping ([AbstractCard]) -> Void,
              onFailureNoCache: @escaping () -> Void) {
        cancel()
        let wikiTagData = WikiHelper.shared.extractWikiTagData(tags: tags)
        let rawKey = Self.buildRawKey(wikiTagData)
        guard !rawKey.isEmpty else {
            DispatchQueue.main.async {
                onComplete([])
            }
            return
        }
        guard AFNetworkReachabilityManagerWrapper.isReachable() else {
            loadFromCache(rawKey: rawKey, wikiTagData: wikiTagData, onComplete: onComplete, onFailureNoCache: onFailureNoCache)
            return
        }

        run({ [cache] in
            var rawResponse: String?
            let listener = AstroGalleryNetworkResponseListener { rawResponse = $0 }
            let images = WikiCoreHelper.shared.getWikiImageList(tags: tags, listener: listener)
            guard let rawResponse else {
                return cache.exists(rawKey: rawKey) ? Self.cachedImages(cache, rawKey: rawKey, wikiTagData: wikiTagData) : images
            }
            cache.save(rawKey: rawKey, json: rawResponse)
            return images
        }, onComplete: onComplete)
    }

    func cancel() {
        activeToken = nil
    }

    private func loadFromCache(rawKey: String,
                               wikiTagData: WikiHelper.WikiTagData,
                               onComplete: @escaping ([AbstractCard]) -> Void,
                               onFailureNoCache: @escaping () -> Void) {
        guard cache.exists(rawKey: rawKey) else {
            DispatchQueue.main.async {
                onFailureNoCache()
            }
            return
        }
        run({ [cache] in
            Self.cachedImages(cache, rawKey: rawKey, wikiTagData: wikiTagData)
        }, onComplete: onComplete)
    }

    private func run(_ work: @escaping () -> [OsmAndShared.WikiImage],
                     onComplete: @escaping ([AbstractCard]) -> Void) {
        let token = UUID()
        activeToken = token
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let images = work()
            DispatchQueue.main.async { [weak self] in
                guard let self, self.activeToken == token else {
                    return
                }
                self.activeToken = nil
                onComplete(Self.buildCards(images))
            }
        }
    }
}
