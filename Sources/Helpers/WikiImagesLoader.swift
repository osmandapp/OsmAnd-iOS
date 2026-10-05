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

    private static func requestImages(tags: [String: String],
                                      cache: AstroPhotoListCache,
                                      rawKey: String) -> [OsmAndShared.WikiImage]? {
        var rawResponse: String?
        let listener = AstroGalleryNetworkResponseListener { rawResponse = $0 }
        let images = WikiCoreHelper.shared.getWikiImageList(tags: tags, listener: listener)
        guard let rawResponse else {
            return nil
        }
        cache.save(rawKey: rawKey, json: rawResponse)
        return images
    }

    private static func cachedImages(cache: AstroPhotoListCache,
                                     rawKey: String,
                                     wikiTagData: WikiHelper.WikiTagData) -> [OsmAndShared.WikiImage] {
        guard let json = cache.load(rawKey: rawKey), !json.isEmpty else {
            return []
        }
        return WikiCoreHelper.shared.getImagesFromJson(json: json, wikiImages: wikiTagData.wikiImages)
    }

    private static func tagImages(_ wikiTagData: WikiHelper.WikiTagData) -> [OsmAndShared.WikiImage] {
        wikiTagData.wikiImages.compactMap { $0 as? OsmAndShared.WikiImage }
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
        if let file = tagImages(wikiTagData).first?.wikiMediaTag {
            params.append("file=\(file)")
        }
        return params.joined(separator: "&")
    }

    private static func buildCards(_ images: [OsmAndShared.WikiImage]) -> [AbstractCard] {
        images.map { WikiImageCard(wikiImage: WikiImage($0), type: "wikimedia-photo") }
    }

    func load(tags: [String: String], onComplete: @escaping ([AbstractCard]) -> Void) {
        cancel()
        let wikiTagData = WikiHelper.shared.extractWikiTagData(tags: tags)
        let rawKey = Self.buildRawKey(wikiTagData)
        guard !rawKey.isEmpty else {
            DispatchQueue.main.async {
                onComplete([])
            }
            return
        }

        let isReachable = AFNetworkReachabilityManagerWrapper.isReachable()
        run({ [cache] in
            if isReachable, let images = Self.requestImages(tags: tags, cache: cache, rawKey: rawKey) {
                return images
            }
            if cache.exists(rawKey: rawKey) {
                return Self.cachedImages(cache: cache, rawKey: rawKey, wikiTagData: wikiTagData)
            }
            return Self.tagImages(wikiTagData)
        }, onComplete: onComplete)
    }

    func cancel() {
        activeToken = nil
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
