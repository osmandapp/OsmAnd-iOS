//
//  BaseCategory.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 25.04.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class BaseCategory: NSObject {
    
    var key: String
    var translatedName: String
    
    init(key: String, translatedName: String) {
        self.key = key
        self.translatedName = translatedName
    }
}
