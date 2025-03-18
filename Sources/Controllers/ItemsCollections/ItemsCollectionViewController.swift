//
//  ItemsCollectionViewController.swift
//  OsmAnd
//
//  Created by Max Kojin on 19/02/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objc enum ColorCollectionType: Int {
    case colorItems
    case colorizationPaletteItems
    case terrainPaletteItems
    case iconItems
    case bigIconItems
    case poiIconCategories
}

@objc protocol ColorCollectionViewControllerDelegate: AnyObject {
    func selectColorItem(_ colorItem: ColorItem)
    func selectPaletteItem(_ paletteItem: PaletteColor)
    func addAndGetNewColorItem(_ color: UIColor) -> ColorItem
    func changeColorItem(_ colorItem: ColorItem, withColor color: UIColor)
    func duplicateColorItem(_ colorItem: ColorItem) -> ColorItem
    func deleteColorItem(_ colorItem: ColorItem)
}

@objc protocol IconsCollectionViewControllerDelegate: AnyObject {
    func selectIconName(_ iconName: String)
}

@objc protocol PoiIconsCollectionViewControllerDelegate: AnyObject {
    func scrollToCategory(categoryKey: String)
    func scrollToCategory(categoryName: String)
}

@objcMembers
final class ItemsCollectionViewController: OABaseNavbarViewController {
    
    private let iconNamesKey = "iconNamesKey"
    private let poiCategoryNameKey = "poiCategoryNameKey"
    private let headerKey = "headerKey"
    private let chipsTitlesKey = "chipsTitlesKey"
    private let chipsSelectedIndexKey = "chipsSelectedIndexKey"
    
    private let poiTypeNoIconValue = "ic_action_categories_search"
    
    weak var delegate: ColorCollectionViewControllerDelegate?
    weak var iconsDelegate: IconsCollectionViewControllerDelegate?
    weak var hostColorHandler: OAColorCollectionHandler?
    
    var customTitle: String = ""
    var selectedIconColor: UIColor?
    var regularIconColor: UIColor?
    
    var iconImages = [UIImage]()
    var iconCategoties = [IconsCategory]()
    private var iconItems = [String]()
    private var selectedIconItem: String?
    
    private var settings: OAAppSettings
    private var data: OATableDataModel
    
    private var searchController: UISearchController?
    private var lastSearchResults = [OAPOIType]()
    private var inSearchMode = false
    private var searchCancelled = false
    
    private var collectionType: ColorCollectionType
    private var colorsCollection: GradientColorsCollection?
    private var selectedPaletteItem: PaletteColor?
    private var paletteItems: OAConcurrentArray<PaletteColor>?
    private var colorCollectionIndexPath: IndexPath?
    private var colorItems = [ColorItem]()
    private var selectedColorItem: ColorItem?
    private var editColorIndexPath: IndexPath?
    private var isStartedNewColorAdding = false
    
    private var colorCollectionHandler: OAColorCollectionHandler?
    
    
    init(collectionType: ColorCollectionType, items: Any, selectedItem: Any) {
        
        self.collectionType = collectionType
        settings = OAAppSettings.sharedManager()
        data = OATableDataModel()
        
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        
        switch collectionType {
        case .colorItems:
            if let colorItems = items as? [ColorItem] {
                self.colorItems = colorItems
                self.selectedColorItem = selectedItem as? ColorItem
            }
        case .colorizationPaletteItems, .terrainPaletteItems:
            if let collection = items as? GradientColorsCollection {
                self.colorsCollection = collection
                self.paletteItems = OAConcurrentArray()
                self.paletteItems?.addObjectsSync(collection.getColors(.original))
                self.selectedPaletteItem = selectedItem as? PaletteColor
            }
        case .iconItems, .bigIconItems:
            if let icons = items as? [String] {
                self.iconItems = icons
                self.selectedIconItem = selectedItem as? String
            }
        case .poiIconCategories:
            if let categories = items as? [IconsCategory] {
                self.iconCategoties = categories
                self.selectedIconItem = selectedItem as? String
            }
        }
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func registerNotifications() {
        if collectionType == .colorizationPaletteItems || collectionType == .terrainPaletteItems {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(onCollectionDeleted(_:)),
                                                   name: ColorsCollection.collectionDeletedNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(onCollectionCreated(_:)),
                                                   name: ColorsCollection.collectionCreatedNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(onCollectionUpdated(_:)),
                                                   name: ColorsCollection.collectionUpdatedNotification,
                                                   object: nil)
        }
    }
    
    override func registerCells() {
        switch collectionType {
        case .colorItems, .iconItems, .bigIconItems, .poiIconCategories:
            tableView.register(UINib(nibName: OACollectionSingleLineTableViewCell.reuseIdentifier, bundle: nil),
                               forCellReuseIdentifier: OACollectionSingleLineTableViewCell.reuseIdentifier)
            tableView.register(UINib(nibName: OASimpleTableViewCell.reuseIdentifier, bundle: nil),
                               forCellReuseIdentifier: OASimpleTableViewCell.reuseIdentifier)
            
            tableView.register(UINib(nibName: OADividerCell.reuseIdentifier, bundle: nil),
                               forCellReuseIdentifier: OADividerCell.reuseIdentifier)
            
        case .colorizationPaletteItems, .terrainPaletteItems:
            tableView.register(UINib(nibName: OATwoIconsButtonTableViewCell.reuseIdentifier, bundle: nil),
                               forCellReuseIdentifier: OATwoIconsButtonTableViewCell.reuseIdentifier)
        }
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = (collectionType == .colorizationPaletteItems || collectionType == .terrainPaletteItems || collectionType == .poiIconCategories) ? .singleLine : .none
        tableView.backgroundColor = collectionType == .colorItems ? .groupBg : .viewBg
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if collectionType == .colorizationPaletteItems || collectionType == .terrainPaletteItems {
            if let index = paletteItems?.index(ofObjectSync: selectedPaletteItem) as? Int {
                let selectedIndexPath = IndexPath(row: index, section: 0)
                if let isContains = tableView.indexPathsForVisibleRows?.contains(selectedIndexPath), !isContains {
                    tableView.scrollToRow(at: selectedIndexPath, at: .middle, animated: true)
                }
            }
        } else if collectionType == .poiIconCategories {
            setupSearch()
        }
    }
    
    // MARK: - Base UI
    
    override func getTitle() -> String {
        switch collectionType {
        case .colorItems, .colorizationPaletteItems, .terrainPaletteItems:
            return localizedString("shared_string_all_colors")
        case .iconItems, .bigIconItems:
            return localizedString("shared_string_all_icons")
        case .poiIconCategories:
            return localizedString("select_icon_profile_dialog_title")
        }
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_cancel")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        if collectionType == .colorItems {
            if let addButton = createRightNavbarButton(nil, iconName: "ic_custom_add", action: #selector(onRightNavbarButtonPressed), menu: nil) {
                addButton.accessibilityLabel = localizedString("shared_string_add_color")
                return [addButton]
            }
        } else if collectionType == .poiIconCategories {
            if  !inSearchMode,
                let poiIconsDelegate = iconsDelegate as? PoiIconCollectionHandler,
                let menu = poiIconsDelegate.buildTopButtonContextMenu(),
                let categoriesButton = createRightNavbarButton(nil, iconName: "ic_navbar_list", action: nil, menu: menu) {
                return [categoriesButton]
            }
        }
        return []
    }
    
    override func getNavbarColorScheme() -> EOABaseNavbarColorScheme {
        collectionType == .colorItems ? .white : .gray
    }
    
    override func hideFirstHeader() -> Bool {
        collectionType == .colorItems
    }
    
    // MARK: - Data Generation
    
    override func generateData() {
        data = OATableDataModel()
        if collectionType == .colorItems || collectionType == .iconItems || collectionType == .bigIconItems {
            let section = data.createNewSection()
            section.addRow(from: [
                kCellTypeKey: OACollectionSingleLineTableViewCell.reuseIdentifier,
                iconNamesKey: iconItems
            ])
            colorCollectionIndexPath = IndexPath(row: Int(section.rowCount()) - 1, section: Int(data.sectionCount()) - 1)
            
        } else if collectionType == .poiIconCategories {
            
            if inSearchMode {
                tableView.separatorStyle = .singleLine
                let section = data.createNewSection()
                for poiType in lastSearchResults {
                    let iconName = poiType.iconName().lowercased()
                    if !iconName.hasSuffix(poiTypeNoIconValue) && OASvgHelper.hasMxMapImageNamed(iconName) {
                        section.addRow(from: [
                            kCellTypeKey: OASimpleTableViewCell.reuseIdentifier,
                            kCellTitle: poiType.nameLocalized,
                            kCellDescrKey: poiType.category.nameLocalized,
                            kCellIconNameKey: iconName
                        ])
                    }
                }
            } else {
                tableView.separatorStyle = .none
                var selectedChipsIndex = 0
                if let poiIconsDelegate = iconsDelegate as? PoiIconCollectionHandler {
                    selectedChipsIndex = iconCategoties.firstIndex(where: { $0.key == poiIconsDelegate.selectedCatagoryKey }) ?? 0
                }
                
                let chipsSection = data.createNewSection()
                let chipsTitles = iconCategoties.map { $0.translatedName }
                chipsSection.addRow(from: [
                    kCellTypeKey: OACollectionSingleLineTableViewCell.reuseIdentifier,
                    chipsTitlesKey: chipsTitles,
                    chipsSelectedIndexKey: selectedChipsIndex
                ])
                
                for category in iconCategoties {
                    let section = data.createNewSection()
                    section.addRow(from: [
                        kCellTypeKey: OADividerCell.reuseIdentifier,
                        headerKey: category.translatedName]
                    )
                    section.addRow(from: [
                        kCellTypeKey: OACollectionSingleLineTableViewCell.reuseIdentifier,
                        poiCategoryNameKey: category.key,
                        iconNamesKey: category.iconKeys
                    ])
                    section.addRow(from: [kCellTypeKey: OADividerCell.reuseIdentifier])
                }
            }
            
        } else {
            let palettesSection = data.createNewSection()
            paletteItems?.asArray().forEach { paletteColor in
                if let color = paletteColor as? PaletteColor {
                    palettesSection.addRow(generateRowData(for: color))
                }
            }
        }
    }
    
    override func getTitleForHeader(_ section: Int) -> String {
        if let header = data.sectionData(for: UInt(section)).getRow(0).obj(forKey: headerKey) as? String {
            return header
        }
        return ""
    }
    
    private func generateRowData(for paletteColor: PaletteColor) -> OATableRowData {
        let paletteColorRow = OATableRowData()
        paletteColorRow.cellType = OATwoIconsButtonTableViewCell.reuseIdentifier
        paletteColorRow.key = "paletteColor"
        paletteColorRow.title = paletteColor.toHumanString()
        paletteColorRow.setObj(paletteColor, forKey: "palette")
        
        if let gradientPaletteColor = paletteColor as? PaletteGradientColor,
           let prefix = colorsCollection?.getFileNamePrefix() {
            var colorPaletteFileName = ""
            
            if colorsCollection?.isTerrainType() == true {
                let typeName = gradientPaletteColor.typeName
                let paletteName = gradientPaletteColor.paletteName
                
                var secondPart = ""
                if paletteName == typeName {
                    if TerrainMode.TerrainTypeWrapper.getNameFor(type: TerrainType.height) == paletteName {
                        secondPart = TerrainMode.altitudeDefaultKey
                    } else {
                        secondPart = PaletteGradientColor.defaultName
                    }
                } else {
                    secondPart = paletteName
                }
                colorPaletteFileName = prefix + secondPart + TXT_EXT
            } else {
                colorPaletteFileName = "\(prefix)\(gradientPaletteColor.typeName)\(ColorPaletteHelper.gradientIdSplitter)\(gradientPaletteColor.paletteName)\(TXT_EXT)"
            }
            
            paletteColorRow.setObj(colorPaletteFileName, forKey: "fileName")
        }
        
        return paletteColorRow
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell {
        let item = data.item(for: indexPath)
        
        if item.cellType == OACollectionSingleLineTableViewCell.reuseIdentifier {
            if let cell = tableView.dequeueReusableCell(withIdentifier: OACollectionSingleLineTableViewCell.reuseIdentifier, for: indexPath) as? OACollectionSingleLineTableViewCell {
                if collectionType == .colorItems {
                    setupColorCollectionCell(cell)
                    
                } else if collectionType == .iconItems || collectionType == .bigIconItems || collectionType == .poiIconCategories {
                    
                    if let chipsTitles = item.obj(forKey: chipsTitlesKey) as? [String],
                       let selectedIndex = item.obj(forKey: chipsSelectedIndexKey) as? Int {
                        setupChipsCollectionCell(cell, chipsTitles: chipsTitles, selectedIndex: selectedIndex)
                    } else if let iconNames = item.obj(forKey: iconNamesKey) as? [String] {
                        let poiCategory = item.obj(forKey: poiCategoryNameKey) as? String
                        setupIconCollectionCell(cell, iconNames: iconNames, poiCategoryKey: poiCategory)
                    }
                }
                
                cell.rightActionButtonVisibility(false)
                cell.collectionView.reloadData()
                cell.layoutIfNeeded()
                return cell
            }
        } else if item.cellType == OATwoIconsButtonTableViewCell.reuseIdentifier {
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: OATwoIconsButtonTableViewCell.reuseIdentifier, for: indexPath) as? OATwoIconsButtonTableViewCell {
                
                if let palette = item.obj(forKey: "palette") as? PaletteColor {
                    cell.titleLabel.text = item.title
                    
                    if let gradientPalette = palette as? PaletteGradientColor {
                        let colorPalette = gradientPalette.colorPalette
                        cell.descriptionLabel.text = PaletteCollectionHandler.createDescriptionForPalette(colorPalette, isTerrain: collectionType == .terrainPaletteItems)
                        cell.descriptionLabel.numberOfLines = 1
                        PaletteCollectionHandler.applyGradient(to: cell.secondLeftIconView, with: colorPalette)
                    }
                    
                    cell.secondLeftIconView.layer.cornerRadius = 3
                    cell.leftIconView.image = palette == selectedPaletteItem ? UIImage(named: "ic_checkmark_default") : nil
                    cell.button.setTitle(nil, for: .normal)
                    cell.button.setImage(UIImage(named: "ic_navbar_overflow_menu_outlined")?.withRenderingMode(.alwaysTemplate), for: .normal)
                    cell.button.menu = createPaletteMenu(for: indexPath)
                    cell.button.showsMenuAsPrimaryAction = true
                    
                    return cell
                }
            }
        } else if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            if let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as? OASimpleTableViewCell {
                cell.titleLabel.textColor = .textColorPrimary
                cell.descriptionLabel.textColor = .textColorSecondary
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
                cell.leftIconView.tintColor = .iconColorSelected
                cell.leftIconView.image = OAUtilities.getMxIcon(item.iconName)
                return cell
            }
        } else if item.cellType == OADividerCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OADividerCell.reuseIdentifier, for: indexPath) as! OADividerCell
            cell.backgroundColor = .clear
            cell.dividerColor = .customSeparator
            cell.dividerInsets = UIEdgeInsets.zero
            cell.dividerHight = 1.0 / UIScreen.main.scale
            return cell
        }
        
        return UITableViewCell()
    }
    
    private func setupColorCollectionCell(_ cell: OACollectionSingleLineTableViewCell) {
        if let colorCollectionHandler = OAColorCollectionHandler(data: [colorItems], collectionView: cell.collectionView) {
            colorCollectionHandler.isOpenedFromAllColorsScreen = true
            colorCollectionHandler.hostColorHandler = hostColorHandler
            colorCollectionHandler.delegate = self
            colorCollectionHandler.hostVC = self
            colorCollectionHandler.hostCell = cell
            colorCollectionHandler.hostVCOpenColorPickerButton = navigationItem.rightBarButtonItem?.customView
            colorCollectionHandler.setScrollDirection(.vertical)
            
            if let selectedColorItem, let selectedIndex = colorItems.firstIndex(of: selectedColorItem) {
                colorCollectionHandler.setSelectedIndexPath(IndexPath(row: selectedIndex, section: 0))
            }
            cell.backgroundColor = .systemBackground
            cell.setCollectionHandler(colorCollectionHandler)
            cell.collectionView.isScrollEnabled = false
            cell.useMultyLines = true
            cell.anchorContent(.centerStyle)
        }
    }
    
    private func setupIconCollectionCell(_ cell: OACollectionSingleLineTableViewCell, iconNames: [String], poiCategoryKey: String?) {
        if self.collectionType == .poiIconCategories {
            let poiIconHandler = PoiIconCollectionHandler()
            poiIconHandler.delegate = self
            poiIconHandler.hostVC = self
            poiIconHandler.selectedIconColor = selectedIconColor
            poiIconHandler.regularIconColor = regularIconColor
            poiIconHandler.setScrollDirection(.vertical)
            poiIconHandler.setItemSize(size: 36)
            poiIconHandler.setIconSize(size: 24)
            poiIconHandler.strokeCornerRadius = 18
            poiIconHandler.innerViewCornerRadius = 12
            
            poiIconHandler.roundedSquareCells = false
            poiIconHandler.innerViewCornerRadius = -1
            if let poiCategoryKey {
                poiIconHandler.addProfileIconsCategoryIfNeeded(categoryKey: poiCategoryKey)
                poiIconHandler.selectCategory(poiCategoryKey)
            }
            if let selectedIconItem, let selectedIndex = iconNames.firstIndex(of: selectedIconItem) {
                poiIconHandler.setSelectedIndexPath(IndexPath(row: selectedIndex, section: 0))
            }
            poiIconHandler.setCollectionView(cell.collectionView)
            cell.setCollectionHandler(poiIconHandler)
            cell.disableAnimationsOnStart = true
        } else {
            if let iconHandler = IconCollectionHandler(data: [iconNames], collectionView: cell.collectionView) {
                iconHandler.delegate = self
                iconHandler.hostVC = self
                iconHandler.selectedIconColor = selectedIconColor
                iconHandler.regularIconColor = regularIconColor
                iconHandler.setScrollDirection(.vertical)
                if let selectedIconItem, let selectedIndex = iconNames.firstIndex(of: selectedIconItem) {
                    iconHandler.setSelectedIndexPath(IndexPath(row: selectedIndex, section: 0))
                }
                if collectionType == .iconItems {
                    iconHandler.setItemSize(size: 48)
                    iconHandler.setIconSize(size: 30)
                    iconHandler.roundedSquareCells = false
                    iconHandler.innerViewCornerRadius = -1
                } else if collectionType == .bigIconItems {
                    iconHandler.setItemSize(size: 152)
                    iconHandler.setIconSize(size: 52)
                    iconHandler.roundedSquareCells = true
                    iconHandler.innerViewCornerRadius = 6
                    iconHandler.strokeCornerRadius = 9
                    iconHandler.iconImagesData = [iconImages]
                }
                cell.setCollectionHandler(iconHandler)
                cell.disableAnimationsOnStart = true
            }
        }
        cell.backgroundColor = .systemBackground
        cell.collectionView.isScrollEnabled = false
        cell.useMultyLines = true
        cell.anchorContent(.centerStyle)
    }
    
    private func setupChipsCollectionCell(_ cell: OACollectionSingleLineTableViewCell, chipsTitles: [String], selectedIndex: Int) {
        let handler = ChipsCollectionHandler()
        handler.delegate = self
        handler.setCollectionView(cell.collectionView)
        handler.setScrollDirection(.horizontal)
        cell.setCollectionHandler(handler)
        cell.disableAnimationsOnStart = true
        cell.collectionView.isScrollEnabled = true
        cell.useMultyLines = false
        cell.backgroundColor = .clear
        cell.configureTopOffset(0)
        cell.configureBottomOffset(0)
        handler.titles = chipsTitles
        handler.setSelectedIndexPath(IndexPath(row: selectedIndex, section: 0))
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        super.onRowSelected(indexPath)
        let item = data.item(for: indexPath)
        if item.key == "paletteColor" {
            if let palette = item.obj(forKey: "palette") as? PaletteColor {
                selectedPaletteItem = palette
                delegate?.selectPaletteItem(palette)
            }
            dismiss(animated: true)
        } else if collectionType == .poiIconCategories && inSearchMode {
            if let searchIconName = item.iconName,
                let poiIconsDelegate = iconsDelegate as? PoiIconCollectionHandler {
                selectedIconItem = searchIconName
                poiIconsDelegate.setIconName(searchIconName)
                poiIconsDelegate.selectIconName(searchIconName)
                poiIconsDelegate.allIconsVCDelegate = nil
            }
            searchController?.dismiss(animated: true)
            dismiss(animated: true)
        }
    }
    
    override func sectionsCount() -> Int {
        Int(data.sectionCount())
    }
    
    override func rowsCount(_ section: Int) -> Int {
        Int(data.rowCount(UInt(section)))
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = data.item(for: indexPath)
        if item.cellType == OADividerCell.reuseIdentifier {
            return 1.0 / UIScreen.main.scale
        } else if let chipsTitles = item.obj(forKey: chipsTitlesKey) as? [String] {
            return ChipsCollectionHandler.folderCellHeight
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = data.item(for: indexPath)
        if let chipsTitles = item.obj(forKey: chipsTitlesKey) as? [String] {
            return ChipsCollectionHandler.folderCellHeight
        }
        if let iconsHandler = iconsDelegate as? IconCollectionHandler {
            return iconsHandler.getItemSize().height
        } else if let colorCollectionHandler {
            return colorCollectionHandler.getItemSize().height
        }
        return UITableView.automaticDimension
    }
    
    // MARK: - Additions
    
    private func openColorPicker(with colorItem: ColorItem) {
        let colorPicker = OAColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.closingDelegete = self
        colorPicker.selectedColor = colorItem.getColor()
        colorPicker.modalPresentationStyle = .popover
        colorPicker.popoverPresentationController?.sourceView = navigationItem.rightBarButtonItem?.customView
        navigationController?.present(colorPicker, animated: true)
    }
    
    private func createPaletteMenu(for indexPath: IndexPath) -> UIMenu {
        let duplicateAction = UIAction(title: localizedString("shared_string_duplicate"), image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
            guard let self else { return }
            self.duplicateItem(fromContextMenu: indexPath)
        }
        
        let item = data.item(for: indexPath)
        if let paletteColor = item.obj(forKey: "palette") as? PaletteColor,
           let gradientPaletteColor = paletteColor as? PaletteGradientColor {
            
            let isDefault = gradientPaletteColor.paletteName == PaletteGradientColor.defaultName ||
            (colorsCollection?.isTerrainType() == true &&
             (gradientPaletteColor.typeName == gradientPaletteColor.paletteName ||
              TerrainMode.TerrainTypeWrapper.getNameFor(type: TerrainType.height) == gradientPaletteColor.paletteName))
            
            if !isDefault {
                let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                    guard let self else { return }
                    self.deleteItem(fromContextMenu: indexPath)
                }
                
                let deleteMenu = UIMenu(options: .displayInline, children: [deleteAction])
                return UIMenu(children: [duplicateAction, deleteMenu])
            }
        }
        return UIMenu(children: [duplicateAction])
    }
    
    // MARK: - Selectors
    
    override func onRightNavbarButtonPressed() {
        isStartedNewColorAdding = true
        if let selectedColorItem {
            openColorPicker(with: selectedColorItem)
        }
    }
    
    @objc private func onCollectionDeleted(_ notification: Notification) {
        guard let gradientPaletteColors = notification.object as? [PaletteGradientColor],
              let selectedPaletteItem = selectedPaletteItem as? PaletteGradientColor,
              let paletteItems
        else { return }
        
        let currentGradientPaletteColor = selectedPaletteItem
        var removeCurrent = false
        let currentIndex = paletteItems.index(ofObjectSync: currentGradientPaletteColor)
        
        var indexPathsToDelete = [IndexPath]()
        for paletteColor in gradientPaletteColors {
            let index = paletteItems.index(ofObjectSync: paletteColor)
            if index != NSNotFound {
                paletteItems.removeObjectSync(paletteColor)
                indexPathsToDelete.append(IndexPath(row: Int(index), section: 0))
                if index == currentIndex {
                    removeCurrent = true
                }
            }
        }
        
        guard !indexPathsToDelete.isEmpty else { return }
        
        data.removeItems(at: indexPathsToDelete)
        tableView.performBatchUpdates { [weak self] in
            guard let self else { return }
            self.tableView.deleteRows(at: indexPathsToDelete, with: .automatic)
        } completion: { [weak self] _ in
            guard let self else { return }
            
            if removeCurrent {
                var newCurrentSelected: PaletteColor?
                if let colorsCollection = self.colorsCollection {
                    
                    if colorsCollection.isTerrainType() {
                        let terrainType = TerrainMode.TerrainTypeWrapper.valueOf(typeName: currentGradientPaletteColor.typeName)
                        if let defaultMode = TerrainMode.getDefaultMode(terrainType) {
                            newCurrentSelected = colorsCollection.getPaletteColor(byName: defaultMode.getKeyName())
                        }
                    } else {
                        newCurrentSelected = colorsCollection.getDefaultGradientPalette()
                    }
                }
                
                self.selectedPaletteItem = newCurrentSelected
                if let newCurrentSelected = newCurrentSelected,
                   let currentIndex = self.paletteItems?.index(ofObjectSync: newCurrentSelected) {
                    self.tableView.reloadRows(at: [IndexPath(row: Int(currentIndex), section: 0)], with: .automatic)
                }
            }
        }
    }
    
    @objc private func onCollectionCreated(_ notification: Notification) {
        guard let gradientPaletteColors = notification.object as? [PaletteGradientColor],
        let paletteItems else { return }
        
        var indexPathsToInsert: [IndexPath] = []
        for paletteColor in gradientPaletteColors {
            let index = paletteColor.getIndex() - 1
            let indexPath: IndexPath
            
            if index < paletteItems.countSync() {
                indexPath = IndexPath(row: index, section: 0)
                paletteItems.insertObjectSync(paletteColor, at: UInt(index))
            } else {
                indexPath = IndexPath(row: Int(paletteItems.countSync()), section: 0)
                paletteItems.addObjectSync(paletteColor)
            }
            
            indexPathsToInsert.append(indexPath)
            data.addRow(at: indexPath, row: generateRowData(for: paletteColor))
        }
        
        if !indexPathsToInsert.isEmpty {
            tableView.performBatchUpdates { [weak self] in
                guard let self else { return }
                self.tableView.insertRows(at: indexPathsToInsert, with: .automatic)
            }
        }
    }
    
    @objc private func onCollectionUpdated(_ notification: Notification) {
        guard let gradientPaletteColors = notification.object as? [PaletteGradientColor],
        let paletteItems else { return }
        
        var indexPathsToUpdate: [IndexPath] = []
        for paletteColor in gradientPaletteColors {
            let index = paletteColor.getIndex() - 1
            if index < paletteItems.countSync() {
                let indexPath = IndexPath(row: index, section: 0)
                paletteItems.replaceObject(atIndexSync: UInt(index), with: paletteColor)
                indexPathsToUpdate.append(indexPath)
                data.removeRow(at: indexPath)
                data.addRow(at: indexPath, row: generateRowData(for: paletteColor))
            }
        }
        
        if !indexPathsToUpdate.isEmpty {
            tableView.performBatchUpdates { [weak self] in
                guard let self else { return }
                self.tableView.reloadRows(at: indexPathsToUpdate, with: .automatic)
            }
        }
    }
    
    // MARK: - Search
    
    private func setupSearch() {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchBar.delegate = self
        searchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        tableView.keyboardDismissMode = .onDrag
        setupSearchControllerWithFilter(false)
    }
    
    private func setupSearchControllerWithFilter(_ isFiltered: Bool) {
        guard let searchTextField = searchController?.searchBar.searchTextField else { return }
        
        searchTextField.attributedPlaceholder = NSAttributedString(string: localizedString("shared_string_search"), attributes: [NSAttributedString.Key.foregroundColor: UIColor.textColorSecondary])
        if isFiltered {
            searchTextField.leftView?.tintColor = UIColor.textColorPrimary
        } else {
            searchTextField.leftView?.tintColor = UIColor.textColorSecondary
            searchTextField.tintColor = UIColor.textColorSecondary
        }
    }
    
    private func searchIcons(_ text: String) {
        lastSearchResults.removeAll()

        if text.length <= 1 {
            view.removeSpinner()
            reloadData()
            return
        }
        
        guard let helper = OAQuickSearchHelper.instance(),
              let searchUICore = helper.getCore(),
              var settings = searchUICore.getSearchSettings() else { return}
       
        searchCancelled = false
        settings = settings.setSearch([OAObjectType.withType(EOAObjectType.poiType)])
        searchUICore.update(settings)
        view.addSpinner(inCenterOfCurrentView: true)
        
        let matcher = OAResultMatcher<OASearchResult> { [weak self] res in
            guard let self, let searchResult = res?.pointee else { return true }
            
            if searchResult.objectType == .searchFinished {
                guard let resultCollection = searchUICore.getCurrentSearchResult() else { return true }
                var results = [OAPOIType]()
                
                for result in resultCollection.getCurrentSearchResults() {
                    guard let poiObject = result.object  else { return true }
                    
                    if let poiType = poiObject as? OAPOIType,
                       !poiType.isAdditional() {
                        results.append(poiType)
                    }
                }
                
                self.lastSearchResults.append(contentsOf: results)
                
                DispatchQueue.main.async {
                    self.view.removeSpinner()
                    self.reloadData()
                }
            }
            
            return true
        } cancelledFunc: { [weak self] in
            guard let self else { return false }
            return self.searchCancelled
        }
        
        searchUICore.search(text, delayedExecution: true, matcher: matcher)
    }
    
    private func reloadData() {
        generateData()
        tableView.reloadData()
        setupNavbarButtons()
    }
}

extension ItemsCollectionViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        setupSearchControllerWithFilter(true)
        inSearchMode = true
        lastSearchResults.removeAll()
        reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        setupSearchControllerWithFilter(false)
        inSearchMode = false
        searchCancelled = true
        lastSearchResults.removeAll()
        reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchIcons(searchText.trimWhitespaces())
    }
}
    
extension ItemsCollectionViewController: OACollectionCellDelegate {
    
    func onCollectionItemSelected(_ indexPath: IndexPath, selectedItem: Any?, collectionView: UICollectionView) {
        if collectionType == .iconItems || collectionType == .bigIconItems {
            selectedIconItem = iconItems[indexPath.row]
            if let selectedIconItem {
                iconsDelegate?.selectIconName(selectedIconItem)
            }
            dismiss(animated: true)

        } else if collectionType == .poiIconCategories {
            
            let chipsTitles = iconCategoties.map { $0.translatedName }
            if let selectedName = selectedItem as? String {
                
                if chipsTitles.contains(selectedName) {
                    scrollToCategory(categoryName: selectedName)
                } else {
                    if let poiIconsDelegate = iconsDelegate as? PoiIconCollectionHandler {
                        selectedIconItem = selectedName
                        poiIconsDelegate.setIconName(selectedName)
                        poiIconsDelegate.selectIconName(selectedName)
                        poiIconsDelegate.allIconsVCDelegate = nil
                        dismiss(animated: true)
                    }
                }
            }
            
        } else {
            
            selectedColorItem = colorCollectionHandler?.getSelectedItem()
            if let selectedColorItem {
                delegate?.selectColorItem(selectedColorItem)
            }
            dismiss(animated: true)
        }
    }
    
    func reloadCollectionData() {
        guard let colorCollectionIndexPath else { return }
        tableView.reloadRows(at: [colorCollectionIndexPath], with: .none)
    }
}
    
extension ItemsCollectionViewController: OAColorsCollectionCellDelegate {
    
    func onContextMenuItemEdit(_ indexPath: IndexPath) {
        editColorIndexPath = indexPath
        openColorPicker(with: colorItems[editColorIndexPath?.row ?? 0])
    }
    
    func duplicateItem(fromContextMenu indexPath: IndexPath) {
        guard let delegate else { return }
        
        switch collectionType {
        case .colorItems:
            if let colorCollectionIndexPath {
                let colorItem = colorItems[indexPath.row]
                if let colorCell = tableView.cellForRow(at: colorCollectionIndexPath) as? OACollectionSingleLineTableViewCell {

                    let newIndexPath = IndexPath(row: colorItem.isDefault ? colorCell.collectionView.numberOfItems(inSection: indexPath.section) :
                        indexPath.row + 1,
                                                 section: indexPath.section)
                    
                    let duplicateColorItem = delegate.duplicateColorItem(colorItem)
                    colorItems.insert(duplicateColorItem, at: newIndexPath.row)
                    colorCollectionHandler?.addColor(newIndexPath, newItem: duplicateColorItem)
                }
            }
        case .colorizationPaletteItems, .terrainPaletteItems:
            if let fileName = data.item(for: indexPath).string(forKey: "fileName"),
               !fileName.isEmpty {
                do {
                    try ColorPaletteHelper.shared.duplicateGradient(fileName)
                } catch {
                    print("Failed to duplicate color palette: \(fileName)")
                }
            }
        default:
            break
        }
    }
    
    func deleteItem(fromContextMenu indexPath: IndexPath!) {
        guard let delegate else { return }
        
        switch collectionType {
        case .colorItems:
            if let colorCollectionIndexPath {
                let colorItem = colorItems[indexPath.row]
                colorItems.remove(at: indexPath.row)
                delegate.deleteColorItem(colorItem)
                colorCollectionHandler?.removeColor(indexPath)
            }
        case .colorizationPaletteItems, .terrainPaletteItems:
            if let fileName = data.item(for: indexPath).string(forKey: "fileName"),
               !fileName.isEmpty {
                do {
                    try ColorPaletteHelper.shared.deleteGradient(fileName)
                } catch {
                    print("Failed to delete color palette: \(fileName)")
                }
            }
        default:
            break
        }
    }
}

extension ItemsCollectionViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        guard let delegate = delegate, let colorCollectionIndexPath else { return }
        
        if isStartedNewColorAdding {
            isStartedNewColorAdding = false
            let newColorItem = delegate.addAndGetNewColorItem(viewController.selectedColor)
            colorItems.insert(newColorItem, at: 0)
            colorCollectionHandler?.addAndSelectColor(IndexPath(row: 0, section: 0), newItem: newColorItem)
        } else {
            var editingColor = colorItems[0]
            if let editColorIndexPath {
                editingColor = colorItems[editColorIndexPath.row]
            }
            
            if editingColor.getHexColor() != viewController.selectedColor.toHexARGBString() {
                
                delegate.changeColorItem(editingColor, withColor: viewController.selectedColor)
                if let editColorIndexPath {
                    colorCollectionHandler?.replaceOldColor(editColorIndexPath)
                } else {
                    colorCollectionHandler?.replaceOldColor(IndexPath(row: 0, section: 0))
                }
            }
        }
        tableView.reloadData()
    }
}

extension ItemsCollectionViewController: OAColorPickerViewControllerDelegate {
    
    func onColorPickerDisappear(_ colorPicker: OAColorPickerViewController) {
        isStartedNewColorAdding = false
        editColorIndexPath = nil
    }
}

extension ItemsCollectionViewController: PoiIconsCollectionViewControllerDelegate {
    
    func scrollToCategory(categoryKey: String) {
        // called from poi categoties from top menu
        if let categoryIndex = iconCategoties.firstIndex(where: { $0.key == categoryKey }) {
            if let poiIconsDelegate = iconsDelegate as? PoiIconCollectionHandler {
                poiIconsDelegate.selectedCatagoryKey = categoryKey
                generateData()

                tableView.performBatchUpdates {
                    // reload chips row
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                } completion: { _ in
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: categoryIndex + 1), at: .top, animated: true)
                    self.tableView.layoutIfNeeded()
                }
            }
        }
    }
    
    func scrollToCategory(categoryName: String) {
        // called from poi categoties chips row
        if let categoryIndex = iconCategoties.firstIndex(where: { $0.translatedName == categoryName }) {
            if let poiIconsDelegate = iconsDelegate as? PoiIconCollectionHandler {
                poiIconsDelegate.selectedCatagoryKey = iconCategoties[categoryIndex].key
                generateData()
            }
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: categoryIndex + 1), at: .top, animated: true)
            self.tableView.layoutIfNeeded()
        }
    }
}
