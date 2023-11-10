//
//  WikiImageCacheHelper.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 31/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWikiImageCacheHelper)
@objcMembers
final class WikiImageCacheHelper : OAWebImagesCacheHelper {
    
    override func getDbFilename() -> String! {
        "images_cache.db"
    }
    
    override func getDbFoldername() -> String! {
        "Wiki"
    }
}
