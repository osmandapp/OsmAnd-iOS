//
//  BaseAppearanceIconCollectionHandler.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 26.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class BaseAppearanceIconCollectionHandler: IconCollectionHandler {
    
    let lastUsedKey = "last_used_icons"
    let specialKey = "special"
    
    var categories = [IconsAppearanceCategory]()
    var categoriesByKeyName = [String: IconsAppearanceCategory]()
    var selectedCatagoryKey = ""
    var collectionType: ColorCollectionType?
    weak var allIconsVCDelegate: PoiIconsCollectionViewControllerDelegate?
    
    private let activitiesKey = "activities"
    private let sampleIconKey = "ic_sample"
    private let symbolsKey = "symbols"
    
    override func openAllIconsScreen() {
        guard let hostVC, let collectionType else { return }
        let vc = ItemsCollectionViewController(collectionType: collectionType, items: categories, selectedItem: getSelectedItem())
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
    
    override func getSelectedItem() -> Any {
        if let category = categoriesByKeyName[selectedCatagoryKey],
           let indexPath = getSelectedIndexPath(),
           !category.iconKeys.isEmpty {
           return category.iconKeys[indexPath.row]
        }
        return ""
    }
    
    func setup() {
        initIconCategories()
        setScrollDirection(.horizontal)
    }
    
    func initIconCategories() {
        // Overrides in child classes
    }
    
    func setIconName(_ iconName: String) {
        // Overrides in child classes
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
    
    func initAssetsCategories() {
        readCategoriesFromAssets([specialKey, symbolsKey])
    }
    
    func initActivitiesCategory() {
        var iconKeys = [String]()
        RouteActivityHelper().getActivities().forEach {
            if shouldAppend(iconName: $0.iconName, toIconsList: iconKeys) {
                iconKeys.append($0.iconName)
            }
        }
        if !iconKeys.isEmpty {
            let translatedName = localizedString("shared_string_activity")
            categories.append(IconsAppearanceCategory(key: activitiesKey, translatedName: translatedName, iconKeys: iconKeys))
        }
    }
    
    func shouldAppend(iconName: String, toIconsList iconsList: [String]) -> Bool {
        !iconsList.contains(iconName) && iconName != sampleIconKey && OASvgHelper.hasMxMapImageNamed(iconName)
    }
    
    func initPoiCategories() {
        guard let poiCategories = OAPOIHelper.sharedInstance().poiCategories else { return }
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
    
    func sortCategoriesAndMoveKeyUp(_ key: String) {
        categories.sort { a, b in
            if a.isTopCategory && !b.isTopCategory {
                return true
            } else if !a.isTopCategory && b.isTopCategory {
                return false
            }
            return a.translatedName < b.translatedName
        }
        
        if let index = categories.firstIndex(where: { $0.key == key }) {
            let original = categories.remove(at: index)
            categories.insert(original, at: 0)
        }
    }
    
    func updateMenuElements(_ menuElements: inout [UIMenuElement], with category: IconsAppearanceCategory) {
        menuElements.append(UIAction(title: category.translatedName, image: nil, identifier: nil, handler: { [weak self] _ in
            self?.onMenuItemSelected(name: category.key)
        }))
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
    }
    
    func updateHostCellIfNoIconCategory(_ isNoIcon: Bool) {
        guard let hostCell else { return }
        hostCell.collectionStackViewVisibility(!isNoIcon)
        hostCell.descriptionLabelStackView.isHidden = !isNoIcon
        hostCell.bottomButtonStackView.isHidden = isNoIcon
        hostCell.underTitleView.isHidden = isNoIcon
        hostCell.separatorOffsetViewWidth.constant = isNoIcon ? 20 : .zero
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
    
    func loadAllIconsData() {
        // Overrides in child classes
    }
    
    private func readCategoriesFromAssets(_ categoriesKeys: [String]) {
        guard let json = parsePoiCategoriesJson() else { return }
        for categoryKey in categoriesKeys {
            if let iconsKeys = json.categories[categoryKey], !iconsKeys.icons.isEmpty {
                let translatedName = localizedString("icon_group_" + categoryKey)
                categories.append(IconsAppearanceCategory(key: categoryKey, translatedName: translatedName, iconKeys: iconsKeys.icons, isTopCategory: categoryKey == specialKey))
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
}

struct Categories: Codable {
    let categories: [String: Category]
}

struct Category: Codable {
    let icons: [String]
}
