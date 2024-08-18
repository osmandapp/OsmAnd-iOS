//
//  SharedUtil.swift
//  OsmAnd Maps
//
//  Created by Alexey K on 16.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

@objc(KSharedUtil)
@objcMembers
final class SharedUtil: NSObject {
    static func loadGpx(_ fileName: String) -> GpxFile {
        let file = KFile(filePath: fileName)
        let gpxFile = GpxUtilities.shared.loadGpxFile(file: file)

        let p = WptPt()
        p.bearing = 1.0
        p.category = "1111"
        p.comment = "33333"
        p.getLatitude()

        return gpxFile
    }
}
