//
//  IconsAppearanceCategory.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/02/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class IconsAppearanceCategory: BaseAppearanceCategory {
    
    var iconKeys: [String]
    var isTopCategory: Bool
    
    init(key: String, translatedName: String, iconKeys: [String], isTopCategory: Bool = false) {
        self.iconKeys = iconKeys
        self.isTopCategory = isTopCategory
        super.init(key: key, translatedName: translatedName)
    }
    
    func containsIcon(key: String) -> Bool {
        iconKeys.contains(key)
    }
}
