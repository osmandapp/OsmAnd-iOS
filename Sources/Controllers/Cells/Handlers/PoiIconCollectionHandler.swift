//
//  PoiIconCollectionHandler.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/02/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class PoiIconCollectionHandler: IconCollectionHandler {
    
    var categories = [IconsCategory]()
    var categoriesByName = [String: IconsCategory]()
    var selectedCatagoryKey = ""
    var lastUsedIcons = [String]()
    weak var allIconsVCDelegate: PoiIconsCollectionViewControllerDelegate?
    
    private let LAST_USED_ICONS_LIMIT = 12
    private let POI_CATEGORIES_FILE = "poi_categories.json"
    private let LAST_USED_KEY = "last_used_icons"
    private let SPECIAL_KEY = "special"
    private let SYMBOLS_KEY = "symbols"
    private let ACTIVITIES_KEY = "activities"
    private let SAMPLE_ICON_KEY = "ic_sample"
    
    override init() {
        super.init()
        initIconCategories()
        setScrollDirection(.horizontal)
        selectCategory(LAST_USED_KEY)
    }
    
    func initIconCategories() {
        initLastUsedCategory()
        initAssetsCategories()
        initActivitiesCategory()
        initPoiCategories()
        sortCategories()
        
        for category in categories {
            categoriesByName[category.key] = category
        }
    }
    
    func setIconName(_ iconName: String) {
        for i in 0 ..< categories.count {
            let category = categories[i]
            for j in 0 ..< category.iconKeys.count {
                if iconName == category.iconKeys[j] ||
                    "mx_" + iconName == category.iconKeys[j] {
                    setSelectedIndexPath(IndexPath(row: j, section: 0))
                    selectCategory(category.key)
                    return
                }
            }
        }
        addIconToLastUsed(iconName)
        setSelectedIndexPath(IndexPath(row: 0, section: 0))
        selectCategory(LAST_USED_KEY)
    }
    
    override func getSelectedItem() -> Any {
        if let category = categoriesByName[selectedCatagoryKey],
           let indexPath = getSelectedIndexPath() {
           return category.iconKeys[indexPath.row]
        }
        return ""
    }
    
    func categoryNames() -> [String] {
        categories.map { $0.key }
    }
    
    func selectCategory(_ categoryKey: String) {
        selectedCatagoryKey = categoryKey
        
        if let category = categoriesByName[categoryKey] {
            generateData([category.iconKeys])
            hostCell?.topButton.setTitle(category.translatedName, for: .normal)
            getCollectionView()?.reloadData()
            return
        }
    }
    
    private func initLastUsedCategory() {
        if let icons = OAAppSettings.sharedManager().lastUsedFavIcons.get(), !icons.isEmpty {
            lastUsedIcons = icons
            categories.append(IconsCategory(key: LAST_USED_KEY, translatedName: localizedString("shared_string_last_used"), iconKeys: lastUsedIcons, isTopCategory: true))
        }
    }
    
    private func initAssetsCategories() {
        readCategoriesFromAssets([SPECIAL_KEY, SYMBOLS_KEY])
    }
    
    private func initActivitiesCategory() {
        var iconKeys = [String]()
        for activity in RouteActivityHelper().getActivities() {
            if !iconKeys.contains(activity.iconName) &&
                activity.iconName != SAMPLE_ICON_KEY &&
                OASvgHelper.hasMxMapImageNamed(activity.iconName) {
                iconKeys.append(activity.iconName)
            }
        }
        if !iconKeys.isEmpty {
            let translatedName = localizedString("shared_string_activity")
            categories.append(IconsCategory(key: ACTIVITIES_KEY, translatedName: translatedName, iconKeys: iconKeys))
        }
    }
    
    private func initPoiCategories() {
        if let poiCategories = OAPOIHelper.sharedInstance().poiCategories {
            for poiCategory in poiCategories {
                if var poiTypeList = poiCategory.poiTypes {
                    poiTypeList.sort { $0.nameLocalized < $1.nameLocalized }
                    var iconKeys = [String]()
                    for poiType in poiTypeList {
                        if let iconName = poiType.iconName(),
                            !iconKeys.contains(iconName),
                            iconName != SAMPLE_ICON_KEY,
                            OASvgHelper.hasMxMapImageNamed(iconName) {
                            iconKeys.append(iconName)
                        }
                    }
                    if !iconKeys.isEmpty {
                        categories.append(IconsCategory(key: poiCategory.name, translatedName: poiCategory.nameLocalized, iconKeys: iconKeys))
                    }
                }
            }
        }
    }
    
    private func sortCategories() {
        categories.sort { a, b in
            if a.isTopCategory && !b.isTopCategory {
                return true
            } else if !a.isTopCategory && b.isTopCategory {
                return false
            }
            return a.translatedName < b.translatedName
        }
    }
    
    private func readCategoriesFromAssets(_ categoriesKeys: [String]) {
        if let json = parsePoiCategoriesJson() {
            for categoryKey in categoriesKeys {
                if let iconsKeys = json.categories[categoryKey], !iconsKeys.icons.isEmpty {
                    let translatedName = localizedString("icon_group_" + categoryKey)
                    categories.append(IconsCategory(key: categoryKey, translatedName: translatedName, iconKeys: iconsKeys.icons, isTopCategory: categoryKey == SPECIAL_KEY))
                }
            }
        }
    }
    
    private func parsePoiCategoriesJson() -> Categories? {
        if let path = Bundle.main.path(forResource: "poi_categories", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decoder = JSONDecoder()
                if let parsedData = try? decoder.decode(Categories.self, from: data) {
                    return parsedData
                }
            } catch {
            }
        }
        return nil
    }
    
    override func buildTopButtonContextMenu() -> UIMenu? {
        var menuElements = [UIMenuElement]()
        var previosCategory: IconsCategory?
        
        for i in 0..<categories.count {
            let category = categories[i]
            if let previosCategory, previosCategory.isTopCategory != category.isTopCategory {
                let separator = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [])
                menuElements.append(separator)
            }
            menuElements.append(UIAction(title: category.translatedName, image: nil, identifier: nil, handler: { _ in
                self.onMenuItemSelected(name:category.key)
            }))
            previosCategory = category
        }
  
        return UIMenu(title: "", children: menuElements)
    }
    
    func onMenuItemSelected(name: String) {
        if let allIconsVCDelegate {
            allIconsVCDelegate.scrollToCategoty(name)
        } else {
            if let category = categoriesByName[name] {
                selectCategory(name)
                selectIconName(category.iconKeys[0])
            }
        }
    }
    
    func updateTopButtonName() {
        if let category = categoriesByName[selectedCatagoryKey] {
            hostCell?.topButton.setTitle(category.translatedName + " 􀆏", for: .normal)
        }
    }
    
    func addIconToLastUsed(_ iconKey: String) {
        if let index = lastUsedIcons.firstIndex(of: iconKey) {
            lastUsedIcons.remove(at: index)
        }
        lastUsedIcons.insert(iconKey, at: 0)
        if lastUsedIcons.count > LAST_USED_ICONS_LIMIT {
            lastUsedIcons = Array(lastUsedIcons[0..<LAST_USED_ICONS_LIMIT])
        }
        OAAppSettings.sharedManager().lastUsedFavIcons.set(lastUsedIcons)
    }
    
    override func openAllIconsScreen() {
        guard let hostVC else { return }
        let vc = ItemsCollectionViewController(collectionType: .poiIconCategories, items: categories, selectedItem: getSelectedItem())
        vc.customTitle = customTitle
        vc.iconsDelegate = self
        allIconsVCDelegate = vc
        if let selectedIconColor {
            vc.selectedIconColor = selectedIconColor
        }
        if let regularIconColor {
            vc.regularIconColor = regularIconColor
        }
        hostVC.showModalViewController(vc)
    }
}

private struct Categories: Codable {
    let categories: [String: Category]
}

private struct Category: Codable {
    let icons: [String]
}
