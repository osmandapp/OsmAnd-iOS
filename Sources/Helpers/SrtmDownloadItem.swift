//
//  SrtmDownloadItem.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 11/11/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class SrtmDownloadItem: OADownloadsItem {
    
    static func isSrtmFile(_ fileName: String) -> Bool {
        return fileName.hasSuffix(BINARY_SRTM_MAP_INDEX_EXT) || fileName.hasSuffix(BINARY_SRTM_FEET_MAP_INDEX_EXT)
    }
}
