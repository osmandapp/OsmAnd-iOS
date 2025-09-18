//
//  ImageDownloadRequestModifier.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Kingfisher

struct ImageDownloadRequestModifier: AsyncImageDownloadRequestModifier {
    var onDownloadTaskStarted: (@Sendable (Kingfisher.DownloadTask?) -> Void)?
    private let timeoutInterval: TimeInterval
    
    init(timeoutInterval: TimeInterval = 30,
         onDownloadTaskStarted: (@Sendable (Kingfisher.DownloadTask?) -> Void)? = nil) {
        self.timeoutInterval = timeoutInterval
        self.onDownloadTaskStarted = onDownloadTaskStarted
    }
    
    func modified(for request: URLRequest) -> URLRequest? {
        var r = request
        r.timeoutInterval = timeoutInterval
        return r
    }
}

