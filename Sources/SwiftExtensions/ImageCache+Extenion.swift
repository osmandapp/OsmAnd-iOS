//
//  File.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 06.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Kingfisher

extension ImageCache {
    static let galleryHighResolutionDiskCache: ImageCache = {
        let cache = ImageCache(name: "galleryHighResolutionDiskCache")
        // Disable memory caching
        cache.memoryStorage.config.totalCostLimit = 0
        // Set disk cache size limit 1 Gb
        cache.diskStorage.config.sizeLimit = 1024 * 1024 * 1024
        return cache
    }()
}
