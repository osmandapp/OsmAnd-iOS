//
//  DeepLinkManager.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 16.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class DeepLinkManager: NSObject {
    static let shared = DeepLinkManager()
    
    private let deepLinkParser = DeepLinkParser()
    
    private override init() {
        super.init()
    }
    
    @discardableResult func handleDeepLink(url: URL, rootViewController: OARootViewController?) -> Bool {
        deepLinkParser.parseDeepLink(url, rootViewController: rootViewController)
    }
}
