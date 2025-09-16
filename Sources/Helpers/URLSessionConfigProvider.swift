//
//  URLSessionConfigProvider.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 09.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class URLSessionConfigProvider: NSObject {
    static let onlineAndMapillaryPhotosAPIKey = "onlineAndMapillaryPhotosAPI"
    
    /// Returns OsmAndOnlineAndMapillaryPhotoAPICache configuration with custom cache (40MB RAM / 200MB disk)
    static func onlineAndMapillaryPhotosAPIConfiguration() -> URLSessionConfiguration {
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
    // 30 days
    static let cacheLifetime: TimeInterval = 30 * 24 * 60 * 60
    
    // UserInfo keys
    private static let expirationDateKey = "expirationDate"
    
    // MARK: - URLSession
    
    static func session(for key: String) -> URLSession {
        let config: URLSessionConfiguration
        switch key {
        case URLSessionConfigProvider.onlineAndMapillaryPhotosAPIKey:
            config = URLSessionConfigProvider.onlineAndMapillaryPhotosAPIConfiguration()
        default:
            config = URLSessionConfiguration.default
        }
        return URLSession(configuration: config)
    }
    
    // MARK: - Store
    
    /// Stores a response in cache with expiration date and registers its URL in UserDefaults.
    static func storeResponse(_ response: URLResponse,
                              data: Data,
                              for request: URLRequest,
                              sessionKey: String) {
        let expirationDate = Date().addingTimeInterval(cacheLifetime)
        let userInfo: [AnyHashable: Any] = [expirationDateKey: expirationDate]
        
        let cached = CachedURLResponse(response: response,
                                       data: data,
                                       userInfo: userInfo,
                                       storagePolicy: .allowed)
        
        if let cache = session(for: sessionKey).configuration.urlCache {
            cache.storeCachedResponse(cached, for: request)
            
            // Save the request URL in UserDefaults for this session
            guard let url = request.url?.absoluteString else { return }
            var keys = UserDefaults.standard.stringArray(forKey: cacheKeysKey(for: sessionKey)) ?? []
            if !keys.contains(url) {
                keys.append(url)
                UserDefaults.standard.set(keys, forKey: cacheKeysKey(for: sessionKey))
            }
        }
    }
    
    // MARK: - Fetch
    
    /// Returns cached response if it's not expired. Removes it otherwise.
    static func cachedResponse(for request: URLRequest,
                               sessionKey: String) -> CachedURLResponse? {
        guard let cache = session(for: sessionKey).configuration.urlCache,
              let cached = cache.cachedResponse(for: request) else {
            return nil
        }
        
        return cached
    }
    
    // MARK: - Cleanup
    
    /// Cleans up all expired responses for a given sessionKey
    static func cleanupExpiredResponses(sessionKey: String) {
        guard let cache = session(for: sessionKey).configuration.urlCache else { return }
        let keys = UserDefaults.standard.stringArray(forKey: cacheKeysKey(for: sessionKey)) ?? []

        let now = Date()
        // Filter out expired keys and remove expired cached responses
        let validKeys = keys.compactMap { urlString -> String? in
            guard let url = URL(string: urlString) else { return nil }
            let request = URLRequest(url: url)
            if let cached = cache.cachedResponse(for: request),
               let expirationDate = cached.userInfo?[expirationDateKey] as? Date {
                if expirationDate < now {
                    cache.removeCachedResponse(for: request)
                    return nil
                } else {
                    return urlString
                }
            }
            return nil
        }

        // Save only valid keys back to UserDefaults
        UserDefaults.standard.set(validKeys, forKey: cacheKeysKey(for: sessionKey))
    }
    
    // MARK: - Remove
        
    /// Removes all cached responses for a given sessionKey
    static func removeAllCachedResponses(for sessionKey: String) {
        if let cache = session(for: sessionKey).configuration.urlCache {
            cache.removeAllCachedResponses()
        }
        UserDefaults.standard.removeObject(forKey: cacheKeysKey(for: sessionKey))
    }
    
    /// Removes a single URL key from UserDefaults for the given sessionKey
    private static func removeKey(for url: URL?, sessionKey: String) {
        guard let urlString = url?.absoluteString else { return }
        var keys = UserDefaults.standard.stringArray(forKey: cacheKeysKey(for: sessionKey)) ?? []
        keys.removeAll { $0 == urlString }
        UserDefaults.standard.set(keys, forKey: cacheKeysKey(for: sessionKey))
    }
    
    // MARK: - Helpers
    
    /// Builds a unique UserDefaults key for storing cache URLs per sessionKey
    private static func cacheKeysKey(for sessionKey: String) -> String {
        "URLCacheKeys_\(sessionKey)"
    }
}
