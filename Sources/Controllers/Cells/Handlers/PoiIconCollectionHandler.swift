//
//  PoiIconCollectionHandler.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/02/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class PoiIconCollectionHandler: BasePoiIconCollectionHandler {
    static var cachedCategories = [IconsAppearanceCategory]()
    static var cachedCategoriesByKeyName = [String: IconsAppearanceCategory]()
    
    var isFavoriteList = false
    
    override init() {
        super.init()
        setup()
    }

    init(isFavoriteList: Bool) {
        super.init()
        self.isFavoriteList = isFavoriteList
        setup()
    }
    
    override func initIconCategories() {
        if Self.cachedCategories.isEmpty {
            initOriginalCategory()
            initAssetsCategories()
            initActivitiesCategory()
            initPoiCategories()
            categories.forEach { categoriesByKeyName[$0.key] = $0 }
            Self.cachedCategories = categories
            Self.cachedCategoriesByKeyName = categoriesByKeyName
            loadAllIconsData()
        } else {
            categories = Self.cachedCategories
            categoriesByKeyName = Self.cachedCategoriesByKeyName
        }

        initLastUsedCategory()
        sortCategories()
        initFilteredCategories()
    }
    
    override func initFilteredCategories() {
        categories = categories.filter { isFavoriteList || $0.key != ORIGINAL_KEY }
        categoriesByKeyName = Dictionary(uniqueKeysWithValues: categories.map { ($0.key, $0) })
    }
    
    override func setIconName(_ iconName: String) {
        guard !iconName.isEmpty else { return }
        for category in categories {
            if allIconsVCDelegate == nil && isFavoriteList && category.key == ORIGINAL_KEY && !groupIcons.allSatisfy({ $0 == groupIcons.first }) {
                setSelectedIndexPath(IndexPath(row: 0, section: 0))
                selectCategory(category.key)
                return
            } else {
                for j in 0 ..< category.iconKeys.count {
                    if iconName == category.iconKeys[j] ||
                        "mx_" + iconName == category.iconKeys[j] {
                        selectCategory(category.key)
                        setSelectedIndexPath(IndexPath(row: j, section: 0))
                        return
                    }
                }
            }
        }
        addIconToLastUsed(iconName)
        setSelectedIndexPath(IndexPath(row: 0, section: 0))
        selectCategory(lastUsedKey)
    }

    override func buildTopButtonContextMenu() -> UIMenu? {
        var topMenuElements = [UIMenuElement]()
        var bottomMenuElements = [UIMenuElement]()
        
        for category in categories {
            if category.key == ORIGINAL_KEY || category.key == lastUsedKey || (!isFavoriteList && category.key == specialKey) {
                updateMenuElements(&topMenuElements, with: category)
            } else {
                updateMenuElements(&bottomMenuElements, with: category)
            }
        }
  
        let topMenu = UIMenu(title: "", options: .displayInline, children: topMenuElements)
        let bottomMenu = UIMenu(title: "", options: .displayInline, children: bottomMenuElements)
        return UIMenu(title: "", children: [topMenu, bottomMenu])
    }
    
    override func saveLastUsed(_ icons: [String]) {
        OAAppSettings.sharedManager().lastUsedFavIcons.set(icons)
    }
    
    override func getLastUsed() -> [String] {
        return OAAppSettings.sharedManager().lastUsedFavIcons.get()
    }
}
