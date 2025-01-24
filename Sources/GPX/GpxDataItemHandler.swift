//
//  GpxDataItemHandler.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 23.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import OsmAndShared

@objcMembers
class GpxDataItemHandler: NSObject, GpxDbHelperGpxDataItemCallback {
    var onGpxDataItemReady: ((GpxDataItem) -> Void)?
    func isCancelled() -> Bool {
        return false
    }
    
    func onGpxDataItemReady(item: GpxDataItem) {
        onGpxDataItemReady?(item)
    }
}
