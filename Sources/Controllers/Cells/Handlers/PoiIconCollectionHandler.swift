//
//  PoiIconCollectionHandler.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/02/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class PoiIconCollectionHandler: IconCollectionHandler {
    
    static var cachedCategories = [IconsAppearanceCategory]()
    static var cachedCategoriesByKeyName = [String: IconsAppearanceCategory]()
    
    var categories = [IconsAppearanceCategory]()
    var categoriesByKeyName = [String: IconsAppearanceCategory]()
    var selectedCatagoryKey = ""
    var lastUsedIcons = [String]()
    var groupIcons = [String]()
    var profileIcons = [String]()
    var isFavoriteList = false
    weak var allIconsVCDelegate: PoiIconsCollectionViewControllerDelegate?
    
    private let LAST_USED_ICONS_LIMIT = 12
    private let POI_CATEGORIES_FILE = "poi_categories.json"
    private let ORIGINAL_KEY = "original"
    private let LAST_USED_KEY = "last_used_icons"
    private let SPECIAL_KEY = "special"
    private let SYMBOLS_KEY = "symbols"
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
    
    private func setup() {
        initIconCategories()
        setScrollDirection(.horizontal)
        selectCategory(categoriesByKeyName.keys.contains(LAST_USED_KEY) ? LAST_USED_KEY : SPECIAL_KEY)
    }
    
    func initIconCategories() {
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
    
    func setIconName(_ iconName: String) {
        guard !iconName.isEmpty else { return }
        for category in categories {
            if isFavoriteList && category.key == ORIGINAL_KEY && !groupIcons.allSatisfy({ $0 == groupIcons.first }) {
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
            updateHostCellIfNeeded()
            if let hostCell {
                handlerDelegate?.onCategorySelected(categoryKey, with: hostCell)
            }
            getCollectionView()?.reloadData()
            return
        }
    }
    
    private func initOriginalCategory() {
        categories.append(IconsAppearanceCategory(key: ORIGINAL_KEY, translatedName: localizedString("shared_string_original"), iconKeys: [], isTopCategory: true))
    }
    
    private func initLastUsedCategory() {
        guard !categories.contains(where: { $0.key == LAST_USED_KEY }), let icons = OAAppSettings.sharedManager().lastUsedFavIcons.get(), !icons.isEmpty else { return }
        lastUsedIcons = icons
        let category = IconsAppearanceCategory(key: LAST_USED_KEY, translatedName: localizedString("shared_string_last_used"), iconKeys: lastUsedIcons, isTopCategory: true)
        categories.append(category)
        categoriesByKeyName[LAST_USED_KEY] = category
    }
    
    private func initAssetsCategories() {
        readCategoriesFromAssets([SPECIAL_KEY, SYMBOLS_KEY])
    }
    
    private func initActivitiesCategory() {
        var iconKeys = [String]()
        RouteActivityHelper().getActivities().forEach {
            if shouldAppend(iconName: $0.iconName, toIconsList: iconKeys) {
                iconKeys.append($0.iconName)
            }
        }
        if !iconKeys.isEmpty {
            let translatedName = localizedString("shared_string_activity")
            categories.append(IconsAppearanceCategory(key: ACTIVITIES_KEY, translatedName: translatedName, iconKeys: iconKeys))
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
                        categories.append(IconsAppearanceCategory(key: poiCategory.name, translatedName: poiCategory.nameLocalized, iconKeys: iconKeys))
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
        categories.sort { a, b in
            if a.isTopCategory && !b.isTopCategory {
                return true
            } else if !a.isTopCategory && b.isTopCategory {
                return false
            }
            return a.translatedName < b.translatedName
        }
        
        if let index = categories.firstIndex(where: { $0.key == ORIGINAL_KEY }) {
            let original = categories.remove(at: index)
            categories.insert(original, at: 0)
        }
    }
    
    private func readCategoriesFromAssets(_ categoriesKeys: [String]) {
        if let json = parsePoiCategoriesJson() {
            for categoryKey in categoriesKeys {
                if let iconsKeys = json.categories[categoryKey], !iconsKeys.icons.isEmpty {
                    let translatedName = localizedString("icon_group_" + categoryKey)
                    categories.append(IconsAppearanceCategory(key: categoryKey, translatedName: translatedName, iconKeys: iconsKeys.icons, isTopCategory: categoryKey == SPECIAL_KEY))
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
    
    private func updateMenuElements(_ menuElements: inout [UIMenuElement], with category: IconsAppearanceCategory) {
        menuElements.append(UIAction(title: category.translatedName, image: nil, identifier: nil, handler: { [weak self] _ in
            self?.onMenuItemSelected(name: category.key)
        }))
    }
    
    override func buildTopButtonContextMenu() -> UIMenu? {
        var topMenuElements = [UIMenuElement]()
        var bottomMenuElements = [UIMenuElement]()
        
        for category in categories {
            if category.key == ORIGINAL_KEY || category.key == LAST_USED_KEY || (!isFavoriteList && category.key == SPECIAL_KEY) {
                updateMenuElements(&topMenuElements, with: category)
            } else {
                updateMenuElements(&bottomMenuElements, with: category)
            }
        }
  
        let topMenu = UIMenu(title: "", options: .displayInline, children: topMenuElements)
        let bottomMenu = UIMenu(title: "", options: .displayInline, children: bottomMenuElements)
        return UIMenu(title: "", children: [topMenu, bottomMenu])
    }
    
    func onMenuItemSelected(name: String) {
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
    
    func updateHostCellIfNeeded() {
        updateTopButtonName()
        updateHostCellIfOriginalCategory(selectedCatagoryKey == ORIGINAL_KEY)
    }
    
    private func updateHostCellIfOriginalCategory(_ isOriginal: Bool) {
        guard let hostCell else { return }
        hostCell.collectionStackViewVisibility(!isOriginal)
        hostCell.descriptionLabelStackView.isHidden = !isOriginal
        hostCell.bottomButtonStackView.isHidden = isOriginal
        hostCell.underTitleView.isHidden = isOriginal
        hostCell.separatorOffsetViewWidth.constant = isOriginal ? 20 : .zero
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
        if let lastUsedIconsIndex = categories.firstIndex(where: { $0.key == LAST_USED_KEY }) {
            categories[lastUsedIconsIndex].iconKeys = lastUsedIcons
        }
        OAAppSettings.sharedManager().lastUsedFavIcons.set(lastUsedIcons)
    }
    
    func loadAllIconsData() {
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
                    if category.key == LAST_USED_KEY {
                        lastUsedIcons = category.iconKeys
                        OAAppSettings.sharedManager().lastUsedFavIcons.set(lastUsedIcons)
                    }
                    getCollectionView()?.reloadData()
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
