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
    
    private static let iconLabelsByName: [String: String] = {
        var labels: [String: String] = [:]
        for poiType in OAPOIHelper.sharedInstance().poiTypes {
            if let iconName = poiType.iconName(), labels[iconName] == nil {
                labels[iconName] = poiType.nameLocalized
            }
        }
        for activity in RouteActivityHelper.shared.getActivities() where labels["mx_" + activity.iconName] == nil {
            labels["mx_" + activity.iconName] = activity.label
        }
        return labels
    }()
    
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
    
    static func iconAccessibilityLabel(_ iconName: String) -> String {
        let name = iconName.hasPrefix("mx_") ? String(iconName.dropFirst(3)) : iconName
        let fallbackName = name.hasPrefix("special_") ? String(name.dropFirst(8)) : name
        return iconLabelsByName["mx_" + name] ?? OAPOIHelper.sharedInstance().getPhraseByName(fallbackName) ?? fallbackName
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

    override func updateHostCellIfNeeded() {
        super.updateHostCellIfNeeded()
        updateHostCellIfNoIconCategory(isFavoriteList && selectedCatagoryKey == ORIGINAL_KEY)
    }
    
    override func setIconName(_ iconName: String) {
        if isFavoriteList && iconName.isEmpty {
            selectCategory(ORIGINAL_KEY)
            return
        }
        guard !iconName.isEmpty else { return }
        if allIconsVCDelegate == nil && isFavoriteList && !groupIcons.allSatisfy({ $0 == groupIcons.first }) {
            setSelectedIndexPath(IndexPath(row: 0, section: 0))
            selectCategory(ORIGINAL_KEY)
            return
        }
        if let categoryKey = iconCategoryKey(iconName),
           let category = categoriesByKeyName[categoryKey],
           let index = category.iconKeys.firstIndex(where: { Self.iconNamesMatch($0, iconName) }) {
            setSelectedIndexPath(IndexPath(row: index, section: 0))
            selectCategory(categoryKey)
            return
        }
        addIconToLastUsed(iconName)
        initLastUsedCategory()
        sortCategories()
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
    
    override func lastUsed() -> [String] {
        return OAAppSettings.sharedManager().lastUsedFavIcons.get()
    }

    func setOriginalIcon(_ iconName: String) {
        guard !iconName.isEmpty else { return }
        // Keep the point's Original icon local to this editor, outside the shared category cache.
        let category = IconsAppearanceCategory(key: ORIGINAL_KEY, translatedName: localizedString("shared_string_original"), iconKeys: [iconName], isTopCategory: true)
        categories.removeAll { $0.key == ORIGINAL_KEY }
        categories.insert(category, at: 0)
        categoriesByKeyName[ORIGINAL_KEY] = category
    }

    private func iconCategoryKey(_ iconName: String) -> String? {
        var originalKey: String?
        for category in categories {
            if category.iconKeys.contains(where: { Self.iconNamesMatch($0, iconName) }) {
                if category.key != ORIGINAL_KEY {
                    return category.key
                }
                // The POI icon that is in no other category is shown in Original.
                originalKey = category.key
            }
        }
        return originalKey
    }
}
