//
//  ButtonAppearanceIconCollectionHandler.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 23.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class ButtonAppearanceIconCollectionHandler: BaseAppearanceIconCollectionHandler {
    static let customKey = "custom"
    static let dynamicKey = "dynamic"
    static var cachedCategories = [IconsAppearanceCategory]()
    static var cachedCategoriesByKeyName = [String: IconsAppearanceCategory]()
    
    private var customIconKeys: [String] = []
    
    init(customIconKeys: [String]) {
        super.init()
        self.customIconKeys = customIconKeys
        setup()
    }
    
    override func setup() {
        super.setup()
        collectionType = .baseAppearanceCategories
        selectCategory(Self.dynamicKey)
    }
    
    override func initIconCategories() {
        if Self.cachedCategories.isEmpty {
            initDynamicCategory()
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

        initCustomCategory()
        initLastUsedCategory()
        sortCategories()
    }
    
    override func setIconName(_ iconName: String) {
        guard !iconName.isEmpty else { return }
        for category in categories {
            for j in 0 ..< category.iconKeys.count {
                guard iconName == category.iconKeys[j] else { continue }
                selectCategory(category.key)
                setSelectedIndexPath(IndexPath(row: j, section: 0))
                return
            }
        }
        setSelectedIndexPath(IndexPath(row: 0, section: 0))
        selectCategory(Self.dynamicKey)
    }
    
    override func buildTopButtonContextMenu() -> UIMenu? {
        var topMenuElements = [UIMenuElement]()
        var bottomMenuElements = [UIMenuElement]()
        
        for category in categories {
            if category.key == Self.dynamicKey || category.key == Self.customKey || category.key == specialKey {
                updateMenuElements(&topMenuElements, with: category)
            } else {
                updateMenuElements(&bottomMenuElements, with: category)
            }
        }
  
        let topMenu = UIMenu(title: "", options: .displayInline, children: topMenuElements)
        let bottomMenu = UIMenu(title: "", options: .displayInline, children: bottomMenuElements)
        return UIMenu(title: "", children: [topMenu, bottomMenu])
    }
    
    override func updateHostCellIfNeeded() {
        super.updateHostCellIfNeeded()
        updateHostCellIfNoIconCategory(selectedCatagoryKey == Self.dynamicKey)
    }
    
    override func loadAllIconsData() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            for category in self.categories {
                var brokenIcons = [String]()
                
                for iconName in category.iconKeys {
                    if Self.cachedIcons.object(forKey: iconName as NSString) == nil {
                        var icon = UIImage.templateImageNamed(iconName)
                        if icon == nil {
                            icon = OAUtilities.getMxIcon(iconName.lowercased())
                        }
                        if let icon {
                            Self.cachedIcons.setObject(icon, forKey: iconName as NSString)
                        } else {
                            brokenIcons.append(iconName)
                        }
                    }
                }
                
                if !brokenIcons.isEmpty {
                    let filteredIcons = category.iconKeys.filter { !brokenIcons.contains($0) }
                    self.categoriesByKeyName[category.key]?.iconKeys = filteredIcons
                    getCollectionView()?.reloadData()
                }
            }
        }
    }
    
    private func initDynamicCategory() {
        categories.append(IconsAppearanceCategory(key: Self.dynamicKey, translatedName: localizedString("shared_string_dynamic"), iconKeys: [], isTopCategory: true))
    }
    
    private func initCustomCategory() {
        guard !categories.contains(where: { $0.key == Self.customKey }) else { return }
        let category = IconsAppearanceCategory(key: Self.customKey, translatedName: localizedString("shared_string_custom"), iconKeys: customIconKeys, isTopCategory: true)
        categories.append(category)
        categoriesByKeyName[Self.customKey] = category
    }
    
    private func initLastUsedCategory() {
        guard !categories.contains(where: { $0.key == lastUsedKey }), !OAAppSettings.sharedManager().lastUsedFavIcons.get().isEmpty else { return }
        let category = IconsAppearanceCategory(key: lastUsedKey, translatedName: localizedString("shared_string_last_used"), iconKeys: OAAppSettings.sharedManager().lastUsedFavIcons.get(), isTopCategory: false)
        categories.append(category)
        categoriesByKeyName[lastUsedKey] = category
    }
    
    private func sortCategories() {
        sortCategoriesAndMoveKeyUp(Self.dynamicKey)
    }
}
