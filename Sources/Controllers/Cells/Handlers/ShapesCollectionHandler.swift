//
//  ShapesCollectionHandler.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 25.04.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ShapesCollectionHandler: OABaseCollectionHandler {
    var categories = [ShapesAppearanceCategory]()
    var categoriesByKeyName = [String: ShapesAppearanceCategory]()
    var selectedCatagoryKey = ""
    var groupShapes = [String]()
    var backgroundIconNames = [String]()
    var isFavoriteList = false
    weak var hostVC: OASuperViewController?
    weak var hostCell: OAShapesTableViewCell?
    
    private let ORIGINAL_KEY = "original"
    
    override init() {
        super.init()
        initShapesCategories()
    }
    
    init(backgroundIconNames: [String], isFavoriteList: Bool) {
        super.init()
        self.backgroundIconNames = backgroundIconNames
        self.isFavoriteList = isFavoriteList
        initShapesCategories()
    }
    
    func initShapesCategories() {
        initOriginalCategory()
        initBackgroundCategories()
        
        categories.forEach { categoriesByKeyName[$0.key] = $0 }
    }
    
    override func getCellIdentifier() -> String {
        OAShapesTableViewCell.reuseIdentifier
    }
    
    func selectCategory(_ categoryKey: String, shouldPerformOnCategorySelected: Bool = true) {
        guard !categoryKey.isEmpty else { return }
        
        selectedCatagoryKey = categoryKey
        updateHostCellIfNeeded()
        if let hostCell, shouldPerformOnCategorySelected {
            handlerDelegate?.onCategorySelected(with: hostCell)
        }
    }
    
    func setupDefaultCategory() {
        guard !groupShapes.isEmpty else { return }
        
        if isFavoriteList && !groupShapes.allSatisfy({ $0 == groupShapes.first }) {
            selectCategory(ORIGINAL_KEY)
        } else {
            selectCategory(selectedCatagoryKey)
        }
    }
    
    private func initOriginalCategory() {
        categories.append(ShapesAppearanceCategory(key: ORIGINAL_KEY, translatedName: localizedString("shared_string_original")))
    }
    
    private func initBackgroundCategories() {
        backgroundIconNames.forEach {
            categories.append(ShapesAppearanceCategory(key: $0, translatedName: localizedString("shared_string_\($0)")))
        }
    }
    
    private func updateMenuElements(_ menuElements: inout [UIMenuElement], with category: ShapesAppearanceCategory) {
        menuElements.append(UIAction(title: category.translatedName, image: nil, identifier: nil, handler: { _ in
            self.onMenuItemSelected(name: category.key)
        }))
    }
    
    override func buildTopButtonContextMenu() -> UIMenu? {
        var topMenuElements = [UIMenuElement]()
        var bottomMenuElements = [UIMenuElement]()
        
        for category in categories {
            if category.key == ORIGINAL_KEY {
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
        selectCategory(name)
        if let tag = backgroundIconNames.firstIndex(of: selectedCatagoryKey) {
            hostCell?.updateIcon(with: tag)
        }
    }
    
    func updateHostCellIfNeeded() {
        updateTopButtonName()
        updateHostCellIfFavoriteList()
        updateHostCellIfOriginalCategory(selectedCatagoryKey == ORIGINAL_KEY)
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
    
    private func updateHostCellIfFavoriteList() {
        hostCell?.topButtonVisibility(isFavoriteList)
        hostCell?.valueLabel.isHidden = isFavoriteList
        hostCell?.topRightOffset(isFavoriteList ? 4 : 20)
    }
    
    private func updateHostCellIfOriginalCategory(_ isOriginal: Bool) {
        hostCell?.collectionStackViewVisibility(!isOriginal)
        hostCell?.descriptionLabelStackViewVisibility(isOriginal)
        hostCell?.separatorVisibility(isOriginal)
    }
}
