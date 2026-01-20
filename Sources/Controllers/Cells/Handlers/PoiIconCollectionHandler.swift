//
//  PoiIconCollectionHandler.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/02/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class PoiIconCollectionHandler: BaseAppearanceIconCollectionHandler {
    static var cachedCategories = [IconsAppearanceCategory]()
    static var cachedCategoriesByKeyName = [String: IconsAppearanceCategory]()
    
    var lastUsedIcons = [String]()
    var groupIcons = [String]()
    var profileIcons = [String]()
    var isFavoriteList = false
    
    private let LAST_USED_ICONS_LIMIT = 12
    private let POI_CATEGORIES_FILE = "poi_categories.json"
    private let ORIGINAL_KEY = "original"
    private let ACTIVITIES_KEY = "activities"
    private let PROFILE_ICONS_KEY = "profile_icons"
    private let SAMPLE_ICON_KEY = "ic_sample"
    
    override init() {
        super.init()
        setup()
    }
    
    init(isFavoriteList: Bool) {
        super.init()
        self.isFavoriteList = isFavoriteList
        setup()
    }
    
    override func setup() {
        super.setup()
        collectionType = .poiIconCategories
        selectCategory(categoriesByKeyName.keys.contains(lastUsedKey) ? lastUsedKey : specialKey)
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
    
    private func initFilteredCategories() {
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
    
    func categoryNames() -> [String] {
        categories.map { $0.key }
    }
    
    private func initOriginalCategory() {
        categories.append(IconsAppearanceCategory(key: ORIGINAL_KEY, translatedName: localizedString("shared_string_original"), iconKeys: [], isTopCategory: true))
    }
    
    private func initLastUsedCategory() {
        guard !categories.contains(where: { $0.key == lastUsedKey }), !OAAppSettings.sharedManager().lastUsedFavIcons.get().isEmpty else { return }
        lastUsedIcons = OAAppSettings.sharedManager().lastUsedFavIcons.get()
        let category = IconsAppearanceCategory(key: lastUsedKey, translatedName: localizedString("shared_string_last_used"), iconKeys: lastUsedIcons, isTopCategory: true)
        categories.append(category)
        categoriesByKeyName[lastUsedKey] = category
    }
    
    func addProfileIconsCategoryIfNeeded(categoryKey: String) {
        if categoryKey == PROFILE_ICONS_KEY {
            addProfileIconsCategory()
        }
    }
    
    static func getProfileIconsList() -> [String] {
        [
            "ic_world_globe_dark",
            "ic_action_car_dark",
            "ic_action_taxi",
            "ic_action_truck_dark",
            "ic_action_suv",
            "ic_action_shuttle_bus",
            "ic_action_bus_dark",
            "ic_action_subway",
            "ic_action_train",
            "ic_action_motorcycle_dark",
            "ic_action_enduro_motorcycle",
            "ic_action_motor_scooter",
            "ic_action_bicycle_dark",
            "ic_action_mountain_bike",
            "ic_action_horse",
            "ic_action_pedestrian_dark",
            "ic_action_trekking_dark",
            "ic_action_hill_climbing",
            "ic_action_ski_touring",
            "ic_action_skiing",
            "ic_action_monowheel",
            "ic_action_personal_transporter",
            "ic_action_scooter",
            "ic_action_inline_skates",
            "ic_action_wheelchair",
            "ic_action_wheelchair_forward",
            "ic_action_baby_transport",
            "ic_action_sail_boat_dark",
            "ic_action_aircraft",
            "ic_action_camper",
            "ic_action_campervan",
            "ic_action_helicopter",
            "ic_action_paragliding",
            "ic_aciton_hang_gliding",
            "ic_action_offroad",
            "ic_action_pickup_truck",
            "ic_action_snowmobile",
            "ic_action_ufo",
            "ic_action_utv",
            "ic_action_wagon",
            "ic_action_go_cart",
            "ic_action_openstreetmap_logo",
            "ic_action_kayak",
            "ic_action_motorboat",
            "ic_action_light_aircraft"
        ]
    }
    
    func addProfileIconsCategory() {
        profileIcons = Self.getProfileIconsList()

        let profileIconsCategory = IconsAppearanceCategory(key: PROFILE_ICONS_KEY, translatedName: localizedString("profile_icons"), iconKeys: profileIcons, isTopCategory: true)
        categories.append(profileIconsCategory)
        categoriesByKeyName[PROFILE_ICONS_KEY] = profileIconsCategory
        sortCategories()
    }
    
    private func sortCategories() {
        sortCategoriesAndMoveKeyUp(ORIGINAL_KEY)
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
    
    override func onMenuItemSelected(name: String) {
        guard !name.isEmpty else { return }
        
        if let allIconsVCDelegate {
            allIconsVCDelegate.scrollToCategory(categoryKey: name)
        } else {
            if let category = categoriesByKeyName[name] {
                selectCategory(name)
                category.iconKeys.first.flatMap { selectIconName($0) }
            }
        }
    }
    
    override func updateHostCellIfNeeded() {
        super.updateHostCellIfNeeded()
        updateHostCellIfNoIconCategory(selectedCatagoryKey == ORIGINAL_KEY)
    }
    
    func addIconToLastUsed(_ iconKey: String) {
        guard !iconKey.isEmpty else { return }
        
        if let index = lastUsedIcons.firstIndex(of: iconKey) {
            lastUsedIcons.remove(at: index)
        }
        lastUsedIcons.insert(iconKey, at: 0)
        if lastUsedIcons.count > LAST_USED_ICONS_LIMIT {
            lastUsedIcons = Array(lastUsedIcons[0..<LAST_USED_ICONS_LIMIT])
        }
        if let lastUsedIconsIndex = categories.firstIndex(where: { $0.key == lastUsedKey }) {
            categories[lastUsedIconsIndex].iconKeys = lastUsedIcons
        }
        OAAppSettings.sharedManager().lastUsedFavIcons.set(lastUsedIcons)
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
                        if icon == nil {
                            icon = OAUtilities.getMxIcon("mx_" + iconName.lowercased())
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
                    if category.key == lastUsedKey {
                        lastUsedIcons = category.iconKeys
                        OAAppSettings.sharedManager().lastUsedFavIcons.set(lastUsedIcons)
                    }
                    getCollectionView()?.reloadData()
                }
            }
        }
    }
}
