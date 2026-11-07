//
//  PanoramaxOsmTagHelper.swift
//  OsmAnd
//
//  Created by Eugene on 23.10.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

/// Resolves the picture UUIDs of an OSM `panoramax=*` tag into gallery cards through the
/// Panoramax meta-catalog `/api/search` endpoint. Mirrors `GetOnlineImagesTask` on Android.
@objcMembers
final class PanoramaxOsmTagHelper: NSObject {

    /// Parses the tag value and loads the referenced pictures.
    /// - Parameters:
    ///   - tagValue: raw `panoramax=*` value, one or more semicolon separated UUIDs.
    ///   - session: the online photos session, so responses share its cache.
    ///   - completion: called on the main queue with the cards in OSM order and whether the request failed
    ///     without a usable cached response. An empty or malformed tag completes at once with no cards.
    static func loadCards(tagValue: String?,
                          session: URLSession?,
                          completion: @escaping ([PanoramaxImageCard], Bool) -> Void) {
        let ids = PanoramaxMediaFactory.shared.parseIds(value: tagValue)
        guard !ids.isEmpty,
              let url = URL(string: PanoramaxApi.shared.getSearchUrl(ids: ids)) else {
            completion([], false)
            return
        }

        let sessionKey = URLSessionConfigProvider.onlineAndMapillaryPhotosAPIKey
        let urlSession = session ?? URLSessionManager.session(for: sessionKey)
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)

        let finish: ([PanoramaxImageCard], Bool) -> Void = { cards, failed in
            DispatchQueue.main.async {
                completion(cards, failed)
            }
        }

        urlSession.dataTask(with: request) { data, response, error in
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data {
                URLSessionManager.storeResponse(httpResponse, data: data, for: request, sessionKey: sessionKey)
                finish(cards(from: data, requestedIds: ids), false)
                return
            }

            if (data == nil || response == nil), ErrorHelper.isInternetConnectionError(error as NSError?),
               let cached = URLSessionManager.cachedResponse(for: request, sessionKey: sessionKey) {
                finish(cards(from: cached.data, requestedIds: ids), false)
                return
            }

            NSLog("[PanoramaxOsmTagHelper] Failed to load Panoramax pictures: \(error?.localizedDescription ?? "unexpected response")")
            finish([], true)
        }.resume()
    }

    static func cards(from data: Data, requestedIds: [String]) -> [PanoramaxImageCard] {
        guard let json = String(data: data, encoding: .utf8) else { return [] }
        return PanoramaxMediaFactory.shared
            .fromSearchResponse(response: json, requestedIds: requestedIds)
            .map { PanoramaxImageCard(mediaItem: $0) }
    }
}
