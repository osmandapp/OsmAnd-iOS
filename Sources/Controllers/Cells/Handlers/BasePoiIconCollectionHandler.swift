//
//  BasePoiIconCollectionHandler.swift
//  OsmAnd
//
//  Created by Vitaliy Sova on 25.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objcMembers
class BasePoiIconCollectionHandler: BaseAppearanceIconCollectionHandler {
    let lastUsedIconsLimit = 12
    let POI_CATEGORIES_FILE = "poi_categories.json"
    let ORIGINAL_KEY = "original"
    let ACTIVITIES_KEY = "activities"
    let PROFILE_ICONS_KEY = "profile_icons"
    let SAMPLE_ICON_KEY = "ic_sample"
    
    var lastUsedIcons: [String] = []
    var groupIcons: [String] = []
    var profileIcons: [String] = []
    
    // MARK: - Init / lifecycle
    
    override init() {
        super.init()
        setup()
    }
    
    override func setup() {
        super.setup()
        collectionType = .poiIconCategories
        selectCategory(categoriesByKeyName.keys.contains(lastUsedKey) ? lastUsedKey : specialKey)
    }
    
    // MARK: - Override methods (group)
    
    override func setIconName(_ iconName: String) {
        guard !iconName.isEmpty else { return }
        
        for category in categories {
            let shouldSkipOriginal = allIconsVCDelegate == nil && category.key == ORIGINAL_KEY && !groupIcons.allSatisfy({ $0 == groupIcons.first })

            if shouldSkipOriginal {
                setSelectedIndexPath(IndexPath(row: 0, section: 0))
                selectCategory(category.key)
                return
            } else {
                for (index, iconKey) in category.iconKeys.enumerated() {
                    if iconName == iconKey || "mx_" + iconName == iconKey {
                        selectCategory(category.key)
                        setSelectedIndexPath(IndexPath(row: index, section: 0))
                        return
                    }
                }
            }
        }
        addIconToLastUsed(iconName)
        setSelectedIndexPath(IndexPath(row: 0, section: 0))
        selectCategory(lastUsedKey)
    }
    
    override func updateHostCellIfNeeded() {
        super.updateHostCellIfNeeded()
        updateHostCellIfNoIconCategory(selectedCatagoryKey == ORIGINAL_KEY)
    }
    
    override func loadAllIconsData() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            for category in self.categories {
                var brokenIcons: [String] = []
                
                for iconName in category.iconKeys where Self.cachedIcons.object(forKey: iconName as NSString) == nil {
                    let icon = UIImage.templateImageNamed(iconName)
                    if let icon {
                        Self.cachedIcons.setObject(icon, forKey: iconName as NSString)
                    } else {
                        brokenIcons.append(iconName)
                    }
                }
                
                if !brokenIcons.isEmpty {
                    let filteredIcons = category.iconKeys.filter { !brokenIcons.contains($0) }
                    self.categoriesByKeyName[category.key]?.iconKeys = filteredIcons
                    if category.key == lastUsedKey {
                        lastUsedIcons = category.iconKeys
                        saveLastUsed(lastUsedIcons)
                    }
                    getCollectionView()?.reloadData()
                }
            }
        }
    }
    
    override func buildTopButtonContextMenu() -> UIMenu? {
        var topMenuElements = [UIMenuElement]()
        var bottomMenuElements = [UIMenuElement]()
        
        for category in categories {
            if category.key == ORIGINAL_KEY || category.key == lastUsedKey || category.key == specialKey {
                updateMenuElements(&topMenuElements, with: category)
            } else {
                updateMenuElements(&bottomMenuElements, with: category)
            }
        }
        
        let topMenu = UIMenu(title: "", options: .displayInline, children: topMenuElements)
        let bottomMenu = UIMenu(title: "", options: .displayInline, children: bottomMenuElements)
        
        return UIMenu.composedMenu(from: [topMenuElements, bottomMenuElements])
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
    
    // MARK: - Public API
    
    func categoryNames() -> [String] {
        categories.map { $0.key }
    }
    
    func initOriginalCategory() {
        categories.append(IconsAppearanceCategory(key: ORIGINAL_KEY, translatedName: localizedString("shared_string_original"), iconKeys: [], isTopCategory: true))
    }
    
    func initLastUsedCategory() {
        lastUsedIcons = lastUsed()
        guard !categories.contains(where: { $0.key == lastUsedKey }), !lastUsedIcons.isEmpty else { return }
        let category = IconsAppearanceCategory(key: lastUsedKey, translatedName: localizedString("shared_string_last_used"), iconKeys: lastUsedIcons, isTopCategory: true)
        
        categories.append(category)
        categoriesByKeyName[lastUsedKey] = category
    }
    
    func initFilteredCategories() {
        categories = categories.filter { $0.key != ORIGINAL_KEY }
        categoriesByKeyName = Dictionary(uniqueKeysWithValues: categories.map { ($0.key, $0) })
    }
    
    func addProfileIconsCategoryIfNeeded(categoryKey: String) {
        if categoryKey == PROFILE_ICONS_KEY {
            addProfileIconsCategory()
        }
    }
    
    func addProfileIconsCategory() {
        profileIcons = Self.getProfileIconsList()

        let profileIconsCategory = IconsAppearanceCategory(key: PROFILE_ICONS_KEY, translatedName: localizedString("profile_icons"), iconKeys: profileIcons, isTopCategory: true)
        categories.append(profileIconsCategory)
        categoriesByKeyName[PROFILE_ICONS_KEY] = profileIconsCategory
        sortCategories()
    }
    
    func sortCategories() {
        sortCategoriesAndMoveKeyUp(ORIGINAL_KEY)
    }
    
    func addIconToLastUsed(_ iconKey: String) {
        guard !iconKey.isEmpty else { return }
        
        if let index = lastUsedIcons.firstIndex(of: iconKey) {
            lastUsedIcons.remove(at: index)
        }
        lastUsedIcons.insert(iconKey, at: 0)
        if lastUsedIcons.count > lastUsedIconsLimit {
            lastUsedIcons = Array(lastUsedIcons.prefix(lastUsedIconsLimit))
        }
        if let lastUsedIconsIndex = categories.firstIndex(where: { $0.key == lastUsedKey }) {
            categories[lastUsedIconsIndex].iconKeys = lastUsedIcons
        }
        saveLastUsed(lastUsedIcons)
    }

    // MARK: - Persistence (abstract)
    
    /// Persists the list of recently used icon identifiers.
    /// Subclasses should override this method and provide their own storage implementation.
    func saveLastUsed(_ icons: [String]) {
        fatalError("Subclasses must implement \(#function)")
    }

    /// Returns the list of recently used icon identifiers.
    /// Subclasses should override this method and retrieve the data from their storage.
    func lastUsed() -> [String] {
        fatalError("Subclasses must implement \(#function)")
    }
}

// MARK: - Profile icons

extension BasePoiIconCollectionHandler {
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
}
