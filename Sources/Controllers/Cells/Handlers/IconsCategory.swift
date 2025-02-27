//
//  IconsCategory.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/02/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class IconsCategory {
    
    var key: String
    var translatedName: String
    var iconKeys: [String]
    var isTopCategory: Bool
    
    init(key: String, translatedName: String, iconKeys: [String], isTopCategory: Bool = false) {
        self.key = key
        self.translatedName = translatedName
        self.iconKeys = iconKeys
        self.isTopCategory = isTopCategory
    }
    
    func containsIcon(key: String) -> Bool {
        iconKeys.contains(key)
    }
}
