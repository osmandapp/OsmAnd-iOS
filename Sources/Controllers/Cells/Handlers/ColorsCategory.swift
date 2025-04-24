//
//  ColorsCategory.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 23.04.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAColorsCategory)
@objcMembers
final class ColorsCategory: NSObject {
    
    var key: String
    var translatedName: String
    
    init(key: String, translatedName: String) {
        self.key = key
        self.translatedName = translatedName
    }
}
