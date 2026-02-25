//
//  SmartFolderHelperBridge.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 25.02.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import OsmAndShared

@objcMembers
final class SharedLibSmartFolderHelper: NSObject {
    static let shared = SmartFolderHelper()
}
