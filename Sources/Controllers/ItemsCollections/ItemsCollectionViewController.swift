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
    case baseAppearanceCategories
    case profileIconCategories
}

@objc protocol ColorCollectionViewControllerDelegate: AnyObject {
    func selectColorItem(_ colorItem: PaletteItemSolid)
    @objc optional func selectPaletteItem(_ paletteItem: PaletteItemGradient)
    @discardableResult func addAndGetNewColorItem(_ color: UIColor) -> PaletteItemSolid
    func changeColorItem(_ colorItem: PaletteItemSolid, withColor color: UIColor)
    @discardableResult func duplicateColorItem(_ colorItem: PaletteItemSolid) -> PaletteItemSolid
    func deleteColorItem(_ colorItem: PaletteItemSolid)
    @objc optional func reloadData()
}

@objc protocol IconsCollectionViewControllerDelegate: AnyObject {
    func selectIconName(_ iconName: String)
}

@objc protocol PoiIconsCollectionViewControllerDelegate: AnyObject {
    func scrollToCategory(categoryKey: String)
}

@objcMembers
final class ItemsCollectionViewController: OABaseNavbarViewController {
    
    private let iconNamesKey = "iconNamesKey"
    private let poiCategoryNameKey = "poiCategoryNameKey"
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
    var iconCategories = [IconsAppearanceCategory]()
    private var iconItems = [String]()
    private var selectedIconItem: String?
    private var baseIconHandlers = [IndexPath: BaseAppearanceIconCollectionHandler]()
    
    private var chipsCell: OAFoldersCell?
    private var chipsCellScrollState: OACollectionViewCellState?
    private var selectedChipsIndex = 0
    
    private var settings: OAAppSettings
    private var data: OATableDataModel
    
    private var searchController: UISearchController?
    private var lastSearchResults = [OAPOIType]()
    private var inSearchMode = false
    private var searchCancelled = false
    
    private var collectionType: ColorCollectionType
    private var selectedPaletteItem: PaletteItemGradient?
    private var paletteItems: OAConcurrentArray<PaletteItemGradient>?
    private var colorCollectionIndexPath: IndexPath?
    private var colorItems = [PaletteItemSolid]()
    private var selectedColorItem: PaletteItemSolid?
    private var editColorIndexPath: IndexPath?
    private var isStartedNewColorAdding = false
    private var colorCollectionHandler: OAColorCollectionHandler?
    private var paletteCategory: GradientPaletteCategory? {
        selectedPaletteItem?.properties.fileType.category ?? paletteItems?.asArray().compactMap { ($0 as? PaletteItemGradient)?.properties.fileType.category }.first
    }
    private var addButtonAccessibilityLabel: String? {
        switch collectionType {
        case .colorItems:
            localizedString("shared_string_add_color")
        case .colorizationPaletteItems:
            localizedString("add_palette")
        case .terrainPaletteItems where paletteCategory != .terrainHillshade:
            localizedString("add_palette")
        default:
            nil
        }
    }
    
    init(collectionType: ColorCollectionType, items: Any, selectedItem: Any) {
        
        self.collectionType = collectionType
        settings = OAAppSettings.sharedManager()
        data = OATableDataModel()
        
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        
        switch collectionType {
        case .colorItems:
            if let colorItems = items as? [PaletteItemSolid] {
                self.colorItems = colorItems
                self.selectedColorItem = selectedItem as? PaletteItemSolid
            }
        case .colorizationPaletteItems, .terrainPaletteItems:
            if let paletteItems = items as? [PaletteItemGradient] {
                self.paletteItems = OAConcurrentArray()
                self.paletteItems?.addObjectsSync(paletteItems)
                self.selectedPaletteItem = selectedItem as? PaletteItemGradient
            }
        case .iconItems, .bigIconItems:
            if let icons = items as? [String] {
                self.iconItems = icons
                self.selectedIconItem = selectedItem as? String
            }
        case .poiIconCategories, .profileIconCategories, .baseAppearanceCategories:
            if let categories = items as? [IconsAppearanceCategory] {
                self.iconCategories = categories
                self.selectedIconItem = selectedItem as? String
            }
        }
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }
    
    override func registerCells() {
        switch collectionType {
        case .colorItems, .iconItems, .bigIconItems, .poiIconCategories, .profileIconCategories, .baseAppearanceCategories:
            tableView.register(UINib(nibName: OACollectionSingleLineTableViewCell.reuseIdentifier, bundle: nil),
                               forCellReuseIdentifier: OACollectionSingleLineTableViewCell.reuseIdentifier)
            tableView.register(UINib(nibName: OASimpleTableViewCell.reuseIdentifier, bundle: nil),
                               forCellReuseIdentifier: OASimpleTableViewCell.reuseIdentifier)
            tableView.register(UINib(nibName: OADividerCell.reuseIdentifier, bundle: nil),
                               forCellReuseIdentifier: OADividerCell.reuseIdentifier)
            tableView.register(UINib(nibName: OAFoldersCell.reuseIdentifier, bundle: nil),
                               forCellReuseIdentifier: OAFoldersCell.reuseIdentifier)
            
        case .colorizationPaletteItems, .terrainPaletteItems:
            tableView.register(UINib(nibName: OATwoIconsButtonTableViewCell.reuseIdentifier, bundle: nil),
                               forCellReuseIdentifier: OATwoIconsButtonTableViewCell.reuseIdentifier)
        }
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = collectionType == .colorItems ? .groupBg : .viewBg
        tableView.keyboardDismissMode = .onDrag
        if collectionType != .colorizationPaletteItems && collectionType != .terrainPaletteItems {
            tableView.separatorStyle = .none
        }
        
        chipsCellScrollState = OACollectionViewCellState()
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if collectionType == .colorizationPaletteItems || collectionType == .terrainPaletteItems {
            if let selectedPaletteItem, let paletteItems {
                let index = GradientPaletteHelper.shared.index(of: selectedPaletteItem, in: paletteItems.asArray().compactMap { $0 as? PaletteItemGradient })
                guard index != NSNotFound else { return }
                let selectedIndexPath = IndexPath(row: index, section: 0)
                if let isContains = tableView.indexPathsForVisibleRows?.contains(selectedIndexPath), !isContains {
                    tableView.scrollToRow(at: selectedIndexPath, at: .middle, animated: true)
                }
            }
        } else if collectionType == .poiIconCategories || collectionType == .profileIconCategories || collectionType == .baseAppearanceCategories {
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
        case .poiIconCategories, .profileIconCategories, .baseAppearanceCategories:
            return localizedString("select_icon_profile_dialog_title")
        }
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_close")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        if let addButtonAccessibilityLabel {
            if let addButton = createRightNavbarButton(nil, iconName: "ic_custom_add", action: #selector(onRightNavbarButtonPressed), menu: nil) {
                addButton.accessibilityLabel = addButtonAccessibilityLabel
                return [addButton]
            }
        } else if collectionType == .poiIconCategories || collectionType == .profileIconCategories || collectionType == .baseAppearanceCategories {
            if  !inSearchMode,
                let poiIconsDelegate = iconsDelegate as? BaseAppearanceIconCollectionHandler,
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
        } else if collectionType == .poiIconCategories || collectionType == .profileIconCategories || collectionType == .baseAppearanceCategories {
            
            if inSearchMode {
                tableView.separatorStyle = .singleLine
                let section = data.createNewSection()
                for poiType in lastSearchResults {
                    let iconName = poiType.iconName().lowercased()
                    if !iconName.hasSuffix(poiTypeNoIconValue) && OASvgHelper.hasMxMapImageNamed(iconName) {
                        section.addRow(from: [
                            kCellTypeKey: OASimpleTableViewCell.reuseIdentifier,
                            kCellTitle: poiType.nameLocalized ?? "",
                            kCellDescrKey: poiType.category.nameLocalized ?? "",
                            kCellIconNameKey: iconName
                        ])
                    }
                }
            } else {
                tableView.separatorStyle = .none
                if let poiIconsDelegate = iconsDelegate as? BaseAppearanceIconCollectionHandler {
                    selectedChipsIndex = iconCategories.firstIndex(where: { $0.key == poiIconsDelegate.selectedCatagoryKey }) ?? 0
                }
                let chipsValues = iconCategories.map { ["title": $0.translatedName] }
                
                let chipsSection = data.createNewSection()
                chipsSection.addRow(from: [
                    kCellTypeKey: OAFoldersCell.reuseIdentifier,
                    chipsTitlesKey: chipsValues,
                    chipsSelectedIndexKey: selectedChipsIndex
                ])
                
                for category in iconCategories {
                    let section = data.createNewSection()
                    section.headerText = category.translatedName
                    section.addRow(from: [
                        kCellTypeKey: OACollectionSingleLineTableViewCell.reuseIdentifier,
                        poiCategoryNameKey: category.key,
                        iconNamesKey: category.iconKeys
                    ])
                }
            }
        } else {
            let palettesSection = data.createNewSection()
            paletteItems?.asArray().compactMap { $0 as? PaletteItemGradient }.forEach { paletteItem in
                palettesSection.addRow(generateRowData(for: paletteItem))
            }
        }
    }
    
    override func getTitleForHeader(_ section: Int) -> String {
        data.sectionData(for: UInt(section)).headerText
    }
    
    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        iconsDelegate is BaseAppearanceIconCollectionHandler && section == 0 ? 14 : super.getCustomHeight(forHeader: section)
    }
    
    private func generateRowData(for paletteItem: PaletteItemGradient) -> OATableRowData {
        let paletteColorRow = OATableRowData()
        paletteColorRow.cellType = OATwoIconsButtonTableViewCell.reuseIdentifier
        paletteColorRow.key = "paletteColor"
        paletteColorRow.title = paletteItem.displayName
        paletteColorRow.setObj(paletteItem, forKey: "palette")
        return paletteColorRow
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell {
        let item = data.item(for: indexPath)
        
        if item.cellType == OACollectionSingleLineTableViewCell.reuseIdentifier {
            if let cell = tableView.dequeueReusableCell(withIdentifier: OACollectionSingleLineTableViewCell.reuseIdentifier, for: indexPath) as? OACollectionSingleLineTableViewCell {
                if collectionType == .colorItems {
                    setupColorCollectionCell(cell)
                } else if collectionType == .iconItems || collectionType == .bigIconItems || collectionType == .poiIconCategories || collectionType == .profileIconCategories || collectionType == .baseAppearanceCategories {
                    
                    if let chipsTitles = item.obj(forKey: chipsTitlesKey) as? [String],
                       let selectedIndex = item.obj(forKey: chipsSelectedIndexKey) as? Int {
                        setupChipsCollectionCell(cell, chipsTitles: chipsTitles, selectedIndex: selectedIndex)
                    } else if let iconNames = item.obj(forKey: iconNamesKey) as? [String] {
                        let poiCategory = item.obj(forKey: poiCategoryNameKey) as? String
                        setupIconCollectionCell(cell, indexPath: indexPath, iconNames: iconNames, poiCategoryKey: poiCategory)
                    }
                }
                
                cell.contentView.backgroundColor = .groupBg
                cell.contentView.layer.cornerRadius = 32
                cell.contentView.layer.masksToBounds = true
                cell.backgroundColor = .clear
                
                cell.rightActionButtonVisibility(false)
                cell.collectionView.reloadData()
                cell.layoutIfNeeded()
                return cell
            }
        } else if item.cellType == OATwoIconsButtonTableViewCell.reuseIdentifier {
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: OATwoIconsButtonTableViewCell.reuseIdentifier, for: indexPath) as? OATwoIconsButtonTableViewCell {
                if let palette = item.obj(forKey: "palette") as? PaletteItemGradient {
                    cell.titleLabel.text = item.title
                    cell.descriptionLabel.text = PaletteCollectionHandler.createDescriptionForPalette(palette)
                    cell.descriptionLabel.numberOfLines = 1
                    PaletteCollectionHandler.applyGradient(to: cell.secondLeftIconView, with: palette.getColorPalette())
                    cell.secondLeftIconView.layer.cornerRadius = 3
                    cell.leftIconView.image = palette.id == selectedPaletteItem?.id ? UIImage(named: "ic_checkmark_default") : nil
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
                if let iconName = item.iconName {
                    cell.leftIconView.image = OAUtilities.getMxIcon(iconName)
                } else {
                    cell.leftIconView.image = nil
                }
                return cell
            }
        } else if item.cellType == OADividerCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OADividerCell.reuseIdentifier, for: indexPath) as! OADividerCell
            cell.backgroundColor = .clear
            cell.dividerColor = .customSeparator
            cell.dividerInsets = UIEdgeInsets.zero
            cell.dividerHight = 1.0 / UIScreen.main.scale
            return cell
        } else if item.cellType == OAFoldersCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAFoldersCell.reuseIdentifier, for: indexPath) as! OAFoldersCell
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.collectionView.backgroundColor = .clear
            cell.collectionView.foldersDelegate = self
            cell.collectionView.cellIndex = indexPath
            cell.collectionView.state = chipsCellScrollState
            if let selectedIndex = item.obj(forKey: chipsSelectedIndexKey) as? Int,
                let values = item.obj(forKey: chipsTitlesKey) as? [[String: String]] {
                cell.collectionView.setValues(values, withSelectedIndex: selectedIndex)
            }
            cell.collectionView.contentInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 20)
            cell.collectionView.reloadData()
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    private func setupColorCollectionCell(_ cell: OACollectionSingleLineTableViewCell) {
        let data = (hostColorHandler?.getData() as? [[PaletteItemSolid]]) ?? [colorItems]
        if let items = data.first {
            colorItems = items
        }
        if let handler = OAColorCollectionHandler(data: data, collectionView: cell.collectionView) {
            handler.isOpenedFromAllColorsScreen = true
            handler.hostColorHandler = hostColorHandler
            handler.delegate = self
            handler.hostVC = self
            handler.hostCell = cell
            handler.hostVCOpenColorPickerButton = navigationItem.rightBarButtonItem?.customView
            handler.setScrollDirection(.vertical)
            
            if let selectedColorItem {
                let selectedIndex = OAGPXAppearanceCollection.sharedInstance().index(ofColorItem: selectedColorItem, items: data.first ?? colorItems)
                if selectedIndex != NSNotFound {
                    handler.setSelectedIndexPath(IndexPath(row: selectedIndex, section: 0))
                }
            }

            colorCollectionHandler = handler
            cell.backgroundColor = .systemBackground
            cell.setCollectionHandler(colorCollectionHandler)
            cell.collectionView.isScrollEnabled = false
            cell.disableAnimationsOnStart = true
            cell.useMultyLines = true
            cell.anchorContent(.centerStyle)
        }
    }
    
    private func setupIconCollectionCell(_ cell: OACollectionSingleLineTableViewCell, indexPath: IndexPath, iconNames: [String], poiCategoryKey: String?) {
        if collectionType == .poiIconCategories || collectionType == .profileIconCategories || collectionType == .baseAppearanceCategories {
            var iconHandler: BaseAppearanceIconCollectionHandler
            if let customIconKeys = iconCategories.first(where: { $0.key == ButtonAppearanceIconCollectionHandler.customKey })?.iconKeys, collectionType == .baseAppearanceCategories {
                iconHandler = ButtonAppearanceIconCollectionHandler(customIconKeys: customIconKeys)
            } else if collectionType == .profileIconCategories {
                iconHandler = ProfileIconCollectionHandler()
            } else {
                iconHandler = PoiIconCollectionHandler()
            }
            iconHandler.delegate = self
            iconHandler.hostVC = self
            baseIconHandlers[indexPath] = iconHandler
            iconHandler.selectedIconColor = selectedIconColor
            iconHandler.regularIconColor = regularIconColor
            iconHandler.setScrollDirection(.vertical)
            iconHandler.setItemSize(size: 48)
            iconHandler.setIconBackgroundSize(size: 36)
            iconHandler.setIconSize(size: 24)
            iconHandler.setSpacing(spacing: 10)
            
            iconHandler.roundedSquareCells = false
            iconHandler.innerViewCornerRadius = -1
            if let poiCategoryKey {
                if let poiIconHandler = iconHandler as? PoiIconCollectionHandler {
                    poiIconHandler.addProfileIconsCategoryIfNeeded(categoryKey: poiCategoryKey)
                }
                iconHandler.selectCategory(poiCategoryKey)
            }
            if let selectedIconItem, let selectedIndex = iconNames.firstIndex(of: selectedIconItem) {
                iconHandler.setSelectedIndexPath(IndexPath(row: selectedIndex, section: 0))
            }
            iconHandler.setCollectionView(cell.collectionView)
            cell.setCollectionHandler(iconHandler)
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
                    iconHandler.setIconBackgroundSize(size: 146)
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
            if let palette = item.obj(forKey: "palette") as? PaletteItemGradient {
                selectedPaletteItem = palette
                delegate?.selectPaletteItem?(palette)
            }
            dismissWith(animated: true)
        } else if (collectionType == .poiIconCategories || collectionType == .profileIconCategories || collectionType == .baseAppearanceCategories) && inSearchMode {
            if let searchIconName = item.iconName,
                let poiIconsDelegate = iconsDelegate as? BaseAppearanceIconCollectionHandler {
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
        } else if item.obj(forKey: chipsTitlesKey) is [[String: String]] {
            return 52
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = data.item(for: indexPath)
        if item.obj(forKey: chipsTitlesKey) is [[String: String]] {
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
    
    private func openColorPicker(with colorItem: PaletteItemSolid) {
        let colorPicker = OAColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.closingDelegete = self
        colorPicker.selectedColor = UIColor(argb: Int(colorItem.colorInt))
        colorPicker.modalPresentationStyle = .popover
        colorPicker.popoverPresentationController?.sourceView = navigationItem.rightBarButtonItem?.customView
        navigationController?.present(colorPicker, animated: true)
    }

    private func indexPath(for paletteItem: PaletteItemGradient) -> IndexPath? {
        guard let paletteItems else { return nil }
        let items = paletteItems.asArray().compactMap { $0 as? PaletteItemGradient }
        let row = GradientPaletteHelper.shared.index(of: paletteItem, in: items)
        return row == NSNotFound ? nil : IndexPath(row: row, section: 0)
    }
    
    private func createPaletteMenu(for indexPath: IndexPath) -> UIMenu {
        guard let paletteItem = data.item(for: indexPath).obj(forKey: "palette") as? PaletteItemGradient else { return UIMenu(children: []) }
        let canEditPalette = !paletteItem.isDefault && paletteItem.properties.fileType.category != .terrainHillshade && paletteItem.isEditable
        var menuElements = [UIMenuElement]()
        if canEditPalette {
            let renameAction = UIAction(title: localizedString("shared_string_rename"), image: .icCustomEdit) { [weak self] _ in
                guard let self else { return }
                self.showRenamePaletteAlert(for: paletteItem)
            }
            menuElements.append(UIMenu(options: .displayInline, children: [renameAction]))
        }
        
        var editDuplicateActions = [UIMenuElement]()
        if canEditPalette {
            let editAction = UIAction(title: localizedString("shared_string_edit"), image: .icCustomAppearanceOutlined) { [weak self] _ in
                guard let self else { return }
                GradientPaletteHelper.shared.showEditPaletteEditor(from: self, paletteItem: paletteItem)
            }
            editDuplicateActions.append(editAction)
        }
        let duplicateAction = UIAction(title: localizedString("shared_string_duplicate"), image: .icCustomCopy) { [weak self] _ in
            guard let self else { return }
            guard let indexPath = self.indexPath(for: paletteItem) else { return }
            self.duplicateItem(fromContextMenu: indexPath)
        }
        editDuplicateActions.append(duplicateAction)
        menuElements.append(UIMenu(options: .displayInline, children: editDuplicateActions))
        
        if !paletteItem.isDefault {
            let deleteAction = UIAction(title: localizedString("shared_string_delete"), image: .icCustomTrashOutlined, attributes: .destructive) { [weak self] _ in
                guard let self else { return }
                self.showDeletePaletteAlert(for: paletteItem)
            }
            menuElements.append(UIMenu(options: .displayInline, children: [deleteAction]))
        }

        return UIMenu(children: menuElements)
    }
    
    // MARK: - Selectors
    
    override func onRightNavbarButtonPressed() {
        switch collectionType {
        case .colorItems:
            isStartedNewColorAdding = true
            if let selectedColorItem {
                openColorPicker(with: selectedColorItem)
            }
        case .colorizationPaletteItems, .terrainPaletteItems:
            GradientPaletteHelper.shared.showAddPaletteEditor(from: self, paletteCategory: paletteCategory, sourceView: navigationItem.rightBarButtonItem?.customView)
        default:
            break
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
    
    private func showRenamePaletteAlert(for paletteItem: PaletteItemGradient) {
        let alert = UIAlertController(title: localizedString("shared_string_rename"), message: localizedString("enter_new_name"), preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = paletteItem.displayName
        }
        let applyAction = UIAlertAction(title: localizedString("shared_string_apply"), style: .default) { [weak self, weak alert] _ in
            guard let self, let newName = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            guard !newName.isEmpty else {
                OAUtilities.showToast(localizedString("empty_name"), details: nil, duration: 4, in: self.view)
                return
            }
            guard let indexPath = self.indexPath(for: paletteItem), let renamedPaletteItem = GradientPaletteHelper.shared.renamePaletteItem(paletteItem, newName: newName) else { return }
            self.renameItem(fromContextMenu: indexPath, oldItem: paletteItem, newItem: renamedPaletteItem)
        }
        alert.addAction(applyAction)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        alert.preferredAction = applyAction
        present(alert, animated: true)
    }

    private func showDeletePaletteAlert(for paletteItem: PaletteItemGradient) {
        let alert = UIAlertController(title: "\(localizedString("delete_palette"))?", message: String(format: localizedString("delete_colors_palette_dialog_summary"), paletteItem.displayName), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
            guard let self, let indexPath = self.indexPath(for: paletteItem) else { return }
            self.deleteItem(fromContextMenu: indexPath)
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        if let indexPath = indexPath(for: paletteItem), let cell = tableView.cellForRow(at: indexPath) {
            alert.popoverPresentationController?.sourceView = cell
            alert.popoverPresentationController?.sourceRect = cell.bounds
        }
        present(alert, animated: true)
    }
    
    func applyPaletteEditorResult(_ paletteItem: PaletteItemGradient, replacing originalId: String?) {
        guard let paletteItems else { return }
        paletteItems.replaceAll(withObjectsSync: GradientPaletteHelper.shared.paletteItems(category: paletteItem.properties.fileType.category, sortMode: .lastUsedTime))
        if originalId == nil || selectedPaletteItem?.id == originalId {
            selectedPaletteItem = paletteItem
            delegate?.selectPaletteItem?(paletteItem)
        } else {
            delegate?.reloadData?()
        }

        reloadData()
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
    
    func onCollectionItemSelected(_ indexPath: IndexPath, selectedItem: Any?, collectionView: UICollectionView, shouldDismiss: Bool) {
        if collectionType == .iconItems || collectionType == .bigIconItems {
            selectedIconItem = iconItems[indexPath.row]
            if let selectedIconItem {
                iconsDelegate?.selectIconName(selectedIconItem)
            }
        } else if collectionType == .poiIconCategories || collectionType == .profileIconCategories || collectionType == .baseAppearanceCategories {
            if let baseIconsDelegate = iconsDelegate as? BaseAppearanceIconCollectionHandler,
               let selectedName = selectedItem as? String {
                
                for handler in baseIconHandlers.values {
                    if !handler.iconNamesData.isEmpty,
                       let selectedIndex = handler.iconNamesData[0].firstIndex(of: selectedName) {
                        let selectedIndexPath = IndexPath(row: selectedIndex, section: 0)
                        handler.setSelectedIndexPath(selectedIndexPath)
                    } else {
                        handler.setSelectedIndexPath(IndexPath(row: -1, section: 0))
                    }
                    handler.getCollectionView().reloadData()
                }
                
                selectedIconItem = selectedName
                baseIconsDelegate.setIconName(selectedName)
                baseIconsDelegate.selectIconName(selectedName)
                baseIconsDelegate.allIconsVCDelegate = nil
            }
        } else {
            selectedColorItem = colorCollectionHandler?.getSelectedItem()
            if let selectedColorItem {
                delegate?.selectColorItem(selectedColorItem)
            }
        }
        
        if shouldDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                super.onLeftNavbarButtonPressed()
            }
        }
    }
    
    func reloadCollectionData() {
        guard let colorCollectionIndexPath else { return }
        tableView.reloadRows(at: [colorCollectionIndexPath], with: .none)
    }
}
    
extension ItemsCollectionViewController: OAColorsCollectionCellDelegate {
    
    func renameItem(fromContextMenu indexPath: IndexPath, oldItem: PaletteItemGradient, newItem: PaletteItemGradient) {
        guard let paletteItems else { return }
        paletteItems.removeObject(atIndexSync: UInt(indexPath.row))
        paletteItems.insertObjectSync(newItem, at: UInt(indexPath.row))
        data.removeRow(at: indexPath)
        data.addRow(at: indexPath, row: generateRowData(for: newItem))
        if selectedPaletteItem?.id == oldItem.id {
            selectedPaletteItem = newItem
            delegate?.selectPaletteItem?(newItem)
        } else {
            delegate?.reloadData?()
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func onContextMenuItemEdit(_ indexPath: IndexPath) {
        editColorIndexPath = indexPath
        openColorPicker(with: colorItems[editColorIndexPath?.row ?? 0])
    }
    
    func duplicateItem(fromContextMenu indexPath: IndexPath) {
        switch collectionType {
        case .colorItems:
            guard let delegate else { return }
            if colorCollectionIndexPath != nil {
                let colorItem = colorItems[indexPath.row]
                let newIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                let duplicateColorItem = delegate.duplicateColorItem(colorItem)
                guard duplicateColorItem.id != colorItem.id else { return }
                colorItems.insert(duplicateColorItem, at: newIndexPath.row)
                colorCollectionHandler?.addColor(newIndexPath, newItem: duplicateColorItem)
            }
        case .colorizationPaletteItems, .terrainPaletteItems:
            guard let paletteItem = data.item(for: indexPath).obj(forKey: "palette") as? PaletteItemGradient, let duplicatedPaletteItem = GradientPaletteHelper.shared.duplicatePaletteItem(paletteItem), let paletteItems else { return }
            let newIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
            paletteItems.insertObjectSync(duplicatedPaletteItem, at: UInt(newIndexPath.row))
            data.addRow(at: newIndexPath, row: generateRowData(for: duplicatedPaletteItem))
            tableView.insertRows(at: [newIndexPath], with: .automatic)
            delegate?.reloadData?()
        default:
            break
        }
    }
    
    func deleteItem(fromContextMenu indexPath: IndexPath) {
        switch collectionType {
        case .colorItems:
            guard let delegate else { return }
            if colorCollectionIndexPath != nil {
                let colorItem = colorItems[indexPath.row]
                colorItems.remove(at: indexPath.row)
                delegate.deleteColorItem(colorItem)
                colorCollectionHandler?.removeColor(indexPath)
            }
        case .colorizationPaletteItems, .terrainPaletteItems:
            guard let paletteItem = data.item(for: indexPath).obj(forKey: "palette") as? PaletteItemGradient, let paletteItems, GradientPaletteHelper.shared.deletePaletteItem(paletteItem) else { return }
            paletteItems.removeObject(atIndexSync: UInt(indexPath.row))
            data.removeRow(at: indexPath)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            if selectedPaletteItem?.id == paletteItem.id {
                let paletteItemsArray = paletteItems.asArray().compactMap { $0 as? PaletteItemGradient }
                selectedPaletteItem = GradientPaletteHelper.shared.defaultPaletteItem(category: paletteItem.properties.fileType.category) ?? paletteItemsArray.first
                let selectedIndex = GradientPaletteHelper.shared.index(of: selectedPaletteItem, in: paletteItemsArray)
                if selectedIndex != NSNotFound {
                    tableView.reloadRows(at: [IndexPath(row: selectedIndex, section: indexPath.section)], with: .automatic)
                }
            }
            delegate?.reloadData?()
        default:
            break
        }
    }
}

extension ItemsCollectionViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        guard let delegate, colorCollectionIndexPath != nil else { return }
        if isStartedNewColorAdding {
            isStartedNewColorAdding = false
            let newColorItem = delegate.addAndGetNewColorItem(viewController.selectedColor)
            colorItems.insert(newColorItem, at: 0)
            selectedColorItem = newColorItem
            colorCollectionHandler?.addAndSelectColor(IndexPath(row: 0, section: 0), newItem: newColorItem)
            delegate.selectColorItem(newColorItem)
        } else {
            let editingIndexPath = editColorIndexPath ?? IndexPath(row: 0, section: 0)
            guard editingIndexPath.row < colorItems.count else { return }
            var editingColor = colorItems[editingIndexPath.row]
            let colorInt = Int32(UIColor.toNumber(from: viewController.selectedColor.toHexARGBString()))
            if editingColor.colorInt != colorInt {
                if let colorCollectionHandler {
                    colorCollectionHandler.changeColorItem(editingColor, with: viewController.selectedColor)
                } else {
                    delegate.changeColorItem(editingColor, withColor: viewController.selectedColor)
                }
                if let data = colorCollectionHandler?.getData() as? [[PaletteItemSolid]], editingIndexPath.section < data.count, editingIndexPath.row < data[editingIndexPath.section].count {
                    let newColorItem = data[editingIndexPath.section][editingIndexPath.row]
                    colorItems[editingIndexPath.row] = newColorItem
                    selectedColorItem = newColorItem
                    editingColor = newColorItem
                }
            }

            delegate.selectColorItem(editingColor)
        }
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
        // called from poi categories from navbar context menu
        if let categoryIndex = iconCategories.firstIndex(where: { $0.key == categoryKey }) {
            scrollToIndex(categoryIndex)
        }
    }
    
    func scrollToIndex(_ index: Int) {
        guard let poiIconsDelegate = iconsDelegate as? BaseAppearanceIconCollectionHandler else { return }
        poiIconsDelegate.selectedCatagoryKey = iconCategories[index].key
        selectedChipsIndex = index
        generateData()
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        tableView.scrollToRow(at: IndexPath(row: 0, section: index + 1), at: .top, animated: true)
        tableView.layoutIfNeeded()
    }
}

extension ItemsCollectionViewController: OAFoldersCellDelegate {
    
    func onItemSelected(_ index: Int) {
        // called from poi categories chips row
        scrollToIndex(index)
    }
}
