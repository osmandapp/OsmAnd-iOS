//
//  URLSessionConfigProvider.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 27.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class URLSessionConfigProvider: NSObject {
    static let onlineAndMapillaryPhotosAPIKey = "onlineAndMapillaryPhotosAPI"
    
    /// Returns OsmAndOnlineAndMapillaryPhotoAPICache configuration with custom cache (40MB RAM / 200MB disk)
     class func onlineAndMapillaryPhotosAPIConfiguration() -> URLSessionConfiguration {
        struct Holder {
            static let config: URLSessionConfiguration = {
                let memoryCapacity = 40 * 1024 * 1024
                let diskCapacity = 200 * 1024 * 1024
                let cache = URLCache(memoryCapacity: memoryCapacity,
                                     diskCapacity: diskCapacity,
                                     diskPath: "OsmAndOnlineAndMapillaryPhotosAPICache")

                let config = URLSessionConfiguration.default
                config.urlCache = cache
                config.requestCachePolicy = .useProtocolCachePolicy
                return config
            }()
        }
        return Holder.config
    }
}

@objcMembers
final class URLSessionManager: NSObject {

    class func session(forKey key: String) -> URLSession {
        let config: URLSessionConfiguration
        switch key {
        case URLSessionConfigProvider.onlineAndMapillaryPhotosAPIKey:
            config = URLSessionConfigProvider.onlineAndMapillaryPhotosAPIConfiguration()
        default:
            config = URLSessionConfiguration.default
        }

        return URLSession(configuration: config)
    }

    class func cachedResponse(for request: URLRequest, sessionKey: String) -> CachedURLResponse? {
        session(forKey: sessionKey).configuration.urlCache?.cachedResponse(for: request)
    }

    class func storeResponse(_ response: URLResponse, data: Data, for request: URLRequest, sessionKey: String) {
        let cached = CachedURLResponse(response: response, data: data)
        session(forKey: sessionKey).configuration.urlCache?.storeCachedResponse(cached, for: request)
    }
}
