//
//  ShapesCollectionHandler.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 25.04.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc protocol ShapesCollectionHandlerDelegate: AnyObject {
    func onShapeCategorySelectedWithCell(_ cell: OAShapesTableViewCell)
}

@objcMembers
final class ShapesCollectionHandler: OABaseCollectionHandler {
    var categories = [ShapesCategory]()
    var categoriesByKeyName = [String: ShapesCategory]()
    var selectedCatagoryKey = ""
    var groupShapes = [String]()
    var backgroundIconNames = [String]()
    var isFavoriteList = false
    weak var hostVC: OASuperViewController?
    weak var hostCell: OAShapesTableViewCell?
    weak var handlerDelegate: ShapesCollectionHandlerDelegate?
    
    private let ORIGINAL_KEY = "original"
    
    override init() {
        super.init()
        setup()
    }
    
    init(backgroundIconNames: [String], isFavoriteList: Bool) {
        super.init()
        self.backgroundIconNames = backgroundIconNames
        self.isFavoriteList = isFavoriteList
        setup()
    }
    
    private func setup() {
        initShapesCategories()
        setScrollDirection(.horizontal)
    }
    
    func initShapesCategories() {
        initOriginalCategory()
        initBackgroundCategories()
        
        for category in categories {
            categoriesByKeyName[category.key] = category
        }
    }
    
    override func getCellIdentifier() -> String {
        OAShapesTableViewCell.reuseIdentifier
    }
    
    func selectCategory(_ categoryKey: String, shouldPerformOnCategorySelected: Bool = true) {
        guard !categoryKey.isEmpty else { return }
        
        selectedCatagoryKey = categoryKey
        updateHostCellIfNeeded()
        if let hostCell, shouldPerformOnCategorySelected {
            handlerDelegate?.onShapeCategorySelectedWithCell(hostCell)
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
        categories.append(ShapesCategory(key: ORIGINAL_KEY, translatedName: localizedString("shared_string_original")))
    }
    
    private func initBackgroundCategories() {
        for backgroundIconName in backgroundIconNames {
            categories.append(ShapesCategory(key: backgroundIconName, translatedName: localizedString("shared_string_\(backgroundIconName)")))
        }
    }
    
    private func updateMenuElements(_ menuElements: inout [UIMenuElement], with category: ShapesCategory, and previosCategory: ShapesCategory?) {
        if let previosCategory {
            let separator = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [])
            menuElements.append(separator)
        }
        menuElements.append(UIAction(title: category.translatedName, image: nil, identifier: nil, handler: { _ in
            self.onMenuItemSelected(name: category.key)
        }))
    }
    
    override func buildTopButtonContextMenu() -> UIMenu? {
        var topMenuElements = [UIMenuElement]()
        var bottomMenuElements = [UIMenuElement]()
        var previosCategory: ShapesCategory?
        
        for category in categories {
            if category.key == ORIGINAL_KEY {
                updateMenuElements(&topMenuElements, with: category, and: previosCategory)
            } else {
                updateMenuElements(&bottomMenuElements, with: category, and: previosCategory)
            }
            previosCategory = category
        }
  
        let topMenu = UIMenu(title: "", options: .displayInline, children: topMenuElements)
        let bottomMenu = UIMenu(title: "", options: .displayInline, children: bottomMenuElements)
        return UIMenu(title: "", children: [topMenu, bottomMenu])
    }
    
    func onMenuItemSelected(name: String) {
        guard let category = categoriesByKeyName[name] else { return }
        
        selectCategory(name)
        if let tag = backgroundIconNames.firstIndex(of: selectedCatagoryKey) {
            hostCell?.updateIcon(with: tag)
        }
    }
    
    func updateHostCellIfNeeded() {
        updateTopButtonName()
        updateTopButtonVisibility()
        updateValueLabelVisibility()
        updateCollectionVisibility()
        updateDescriptionVisibility()
        updateSeparatorVisibility()
        updateTopRightOffset()
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
    
    private func updateTopButtonVisibility() {
        hostCell?.topButtonVisibility(isFavoriteList)
    }
    
    private func updateValueLabelVisibility() {
        hostCell?.valueLabelVisibility(!isFavoriteList)
    }
    
    private func updateCollectionVisibility() {
        hostCell?.collectionStackViewVisibility(selectedCatagoryKey != ORIGINAL_KEY)
    }
    
    private func updateDescriptionVisibility() {
        hostCell?.descriptionLabelStackViewVisibility(selectedCatagoryKey == ORIGINAL_KEY)
    }
    
    private func updateSeparatorVisibility() {
        hostCell?.separatorVisibility(selectedCatagoryKey == ORIGINAL_KEY)
    }
    
    private func updateTopRightOffset() {
        hostCell?.topRightOffset(isFavoriteList ? 4 : 20)
    }
}
