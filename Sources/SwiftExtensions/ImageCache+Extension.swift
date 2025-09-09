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
        cache.memoryStorage.config.totalCostLimit = 0
        cache.memoryStorage.config.countLimit = 0
        // Set disk cache size limit 1 Gb
        cache.diskStorage.config.sizeLimit = 1024 * 1024 * 1024
        return cache
    }()
    
    static let onlinePhotoDefaultCache: ImageCache = {
        let cache = ImageCache(name: "onlinePhotoDefaultCache")
        // 100 MB
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        // 1 GB
        cache.diskStorage.config.sizeLimit = 1024 * 1024 * 1024
        return cache
    }()
}
