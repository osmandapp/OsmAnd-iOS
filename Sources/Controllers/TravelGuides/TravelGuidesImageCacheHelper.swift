//
//  TravelGuidesImageCacheHelper.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 30/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OATravelGuidesImageCacheHelper)
@objcMembers
final class TravelGuidesImageCacheHelper : OAWebImagesCacheHelper {
    
    static let sharedDatabase = TravelGuidesImageCacheHelper()
    override private init() {
        super.init()
    }
    
    override func getDbFilename() -> String! {
        "images_cache.db"
    }
    
    override func getDbFoldername() -> String! {
        "Travel"
    }
}
