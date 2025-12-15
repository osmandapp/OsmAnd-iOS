//
//  ShareLinkItem.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit
import LinkPresentation

@objcMembers
final class ShareLinkItem: NSObject, UIActivityItemSource {
    private let url: URL
    private let title: String?
    private let icon: UIImage?
    
    init(url: URL, title: String?, icon: UIImage?) {
        self.url = url
        self.title = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.icon = icon
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        url
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        activityType == .copyToPasteboard ? nil : url
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = url
        metadata.url = url
        if let title, !title.isEmpty {
            metadata.title = title
        }
        
        if let icon {
            let renderer = UIGraphicsImageRenderer(size: icon.size)
            let rendered = renderer.image { _ in
                icon.draw(in: CGRect(origin: .zero, size: icon.size))
            }
            
            let provider = NSItemProvider(object: rendered)
            metadata.imageProvider = provider
            metadata.iconProvider = provider
        }
        
        return metadata
    }
}
