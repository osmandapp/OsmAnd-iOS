//
//  PoiIconCollectionHandler.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/02/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class PoiIconCollectionHandler: IconCollectionHandler {
    
    static var cachedCategories = [IconsCategory]()
    static var cachedCategoriesByKeyName = [String: IconsCategory]()
    
    var categories = [IconsCategory]()
    var categoriesByKeyName = [String: IconsCategory]()
    var selectedCatagoryKey = ""
    var lastUsedIcons = [String]()
    var profileIcons = [String]()
    weak var allIconsVCDelegate: PoiIconsCollectionViewControllerDelegate?
    
    private let LAST_USED_ICONS_LIMIT = 12
    private let POI_CATEGORIES_FILE = "poi_categories.json"
    private let LAST_USED_KEY = "last_used_icons"
    private let SPECIAL_KEY = "special"
    private let SYMBOLS_KEY = "symbols"
    private let TRAVEL_KEY = "travel"
    private let ACTIVITIES_KEY = "activities"
    private let PROFILE_ICONS_KEY = "profile_icons"
    private let SAMPLE_ICON_KEY = "ic_sample"
    
    override init() {
        super.init()
        initIconCategories()
        setScrollDirection(.horizontal)
        selectCategory(LAST_USED_KEY)
    }
    
    func initIconCategories() {
        if Self.cachedCategories.isEmpty {
            initLastUsedCategory()
            initAssetsCategories()
            initActivitiesCategory()
            initPoiCategories()
            sortCategories()
            
            for category in categories {
                categoriesByKeyName[category.key] = category
            }
            
            Self.cachedCategories = categories
            Self.cachedCategoriesByKeyName = categoriesByKeyName
            
            loadAllIconsData()
        } else {
            categories = Self.cachedCategories
            categoriesByKeyName = Self.cachedCategoriesByKeyName
            initLastUsedCategory()
        }
    }
    
    func setIconName(_ iconName: String) {
        guard !iconName.isEmpty else { return }
        
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
        if let category = categoriesByKeyName[selectedCatagoryKey],
           let indexPath = getSelectedIndexPath() {
           return category.iconKeys[indexPath.row]
        }
        return ""
    }
    
    func categoryNames() -> [String] {
        categories.map { $0.key }
    }
    
    func selectCategory(_ categoryKey: String) {
        guard !categoryKey.isEmpty else { return }
        
        selectedCatagoryKey = categoryKey
        
        if let category = categoriesByKeyName[categoryKey] {
            generateData([category.iconKeys])
            updateTopButtonName()
            getCollectionView()?.reloadData()
            return
        }
    }
    
    private func initLastUsedCategory() {
        if let icons = OAAppSettings.sharedManager().lastUsedFavIcons.get(), !icons.isEmpty {
            lastUsedIcons = icons
            let category = IconsCategory(key: LAST_USED_KEY, translatedName: localizedString("shared_string_last_used"), iconKeys: lastUsedIcons, isTopCategory: true)
            categories.append(category)
            categoriesByKeyName[LAST_USED_KEY] = category
        }
    }
    
    private func initAssetsCategories() {
        readCategoriesFromAssets([SPECIAL_KEY, SYMBOLS_KEY, TRAVEL_KEY])
    }
    
    private func initActivitiesCategory() {
        var iconKeys = [String]()
        for activity in RouteActivityHelper().getActivities() {
            if shouldAppend(iconName: activity.iconName, toIconsList: iconKeys) {
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
                guard !["access_private", "osmwiki", "user_defined_other"].contains(poiCategory.name) else { continue }
                if var poiTypeList = poiCategory.poiTypes {
                    poiTypeList.sort { $0.nameLocalized < $1.nameLocalized }
                    var iconKeys = [String]()
                    for poiType in poiTypeList {
                        if let iconName = poiType.iconName(),
                           shouldAppend(iconName: iconName, toIconsList: iconKeys) {
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
    
    private func shouldAppend(iconName: String, toIconsList iconsList: [String]) -> Bool {
        !iconsList.contains(iconName) && iconName != SAMPLE_ICON_KEY && OASvgHelper.hasMxMapImageNamed(iconName)
    }
    
    func addProfileIconsCategoryIfNeeded(categoryKey: String) {
        if categoryKey == PROFILE_ICONS_KEY {
            addProfileIconsCategory()
        }
    }
    
    func addProfileIconsCategory() {
        profileIcons = [
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

        let profileIconsCategory = IconsCategory(key: PROFILE_ICONS_KEY, translatedName: localizedString("profile_icons"), iconKeys: profileIcons, isTopCategory: true)
        categories.append(profileIconsCategory)
        categoriesByKeyName[PROFILE_ICONS_KEY] = profileIconsCategory
        sortCategories()
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
                self.onMenuItemSelected(name: category.key)
            }))
            previosCategory = category
        }
  
        return UIMenu(title: "", children: menuElements)
    }
    
    func onMenuItemSelected(name: String) {
        guard !name.isEmpty else { return }
        
        if let allIconsVCDelegate {
            allIconsVCDelegate.scrollToCategory(categoryKey: name)
        } else {
            if let category = categoriesByKeyName[name] {
                selectCategory(name)
                selectIconName(category.iconKeys[0])
            }
        }
    }
    
    func updateTopButtonName() {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        if let category = categoriesByKeyName[selectedCatagoryKey],
           var iconImage = UIImage(systemName: "chevron.up.chevron.down", withConfiguration: config) {
            iconImage = iconImage.withRenderingMode(.alwaysTemplate)
            let attachment = NSTextAttachment()
            attachment.image = iconImage
            let imageString = NSAttributedString(attachment: attachment)
            
            let attributedString = NSMutableAttributedString(string: category.translatedName + " ")
            attributedString.append(imageString)
            hostCell?.topButton.setAttributedTitle(attributedString, for: .normal)
        }
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
        categories[0].iconKeys = lastUsedIcons
        OAAppSettings.sharedManager().lastUsedFavIcons.set(lastUsedIcons)
    }
    
    func loadAllIconsData() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            for category in self.categories {
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
                        }
                    }
                }
            }
        }
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
        
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        hostVC.present(navController, animated: true)
    }
}

private struct Categories: Codable {
    let categories: [String: Category]
}

private struct Category: Codable {
    let icons: [String]
}
