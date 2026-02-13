//
//  ImageCache+Extension.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 06.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Kingfisher

extension ImageCache {
    static let onlinePhotoHighResolutionDiskCache: ImageCache = {
        let cache = ImageCache(name: "galleryHighResolutionDiskCache")
        // Disable memory caching
        cache.memoryStorage.config.totalCostLimit = 1
        cache.memoryStorage.config.countLimit = 0
        // Set disk cache size limit 1 Gb
        cache.diskStorage.config.sizeLimit = 1024 * 1024 * 1024
        cache.diskStorage.config.expiration = .days(Int(URLSessionManager.cacheLifetime))
        cache.cleanExpiredDiskCache()
        return cache
    }()
    
    static let onlinePhotoAndMapillaryDefaultCache: ImageCache = {
        let cache = ImageCache(name: "onlinePhotoAndMapillaryDefaultCache")
        // 100 MB
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        // 1 GB
        cache.diskStorage.config.sizeLimit = 1024 * 1024 * 1024
        cache.diskStorage.config.expiration = .days(Int(URLSessionManager.cacheLifetime))
        cache.cleanExpiredDiskCache()
        return cache
    }()
    
    static let popularPlacesWikipedia: ImageCache = {
        let cache = ImageCache(name: "popularPlacesWikipedia")
        // 40 MB maximum in RAM
        cache.memoryStorage.config.totalCostLimit = 40 * 1024 * 1024
        // No more than 150 images stored simultaneously
        cache.memoryStorage.config.countLimit = 150
        // Keep images in memory for 60 seconds
        cache.memoryStorage.config.expiration = .seconds(60)
        
        // 200 MB disk storage limit
        cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024
        // Store on disk for 7 days
        cache.diskStorage.config.expiration = .days(7)
        return cache
    }()
}
