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

@objcMembers
final class ItemsCollectionViewController: OABaseNavbarViewController {
    
    weak var delegate: ColorCollectionViewControllerDelegate?
    weak var iconsDelegate: IconsCollectionViewControllerDelegate?
    weak var hostColorHandler: OAColorCollectionHandler?
    
    var customTitle: String = ""
    var selectedIconColor: UIColor?
    var regularIconColor: UIColor?
    
    private var collectionType: ColorCollectionType
    private var colorsCollection: GradientColorsCollection?
    private var selectedPaletteItem: PaletteColor?
    private var paletteItems: OAConcurrentArray<PaletteColor>?
    
    private var settings: OAAppSettings
    private var data: OATableDataModel
    
    private var colorCollectionIndexPath: IndexPath?
    private var colorItems: [ColorItem] = []
    private var selectedColorItem: ColorItem?
    private var editColorIndexPath: IndexPath?
    private var isStartedNewColorAdding = false
    
    private var iconItems: [String] = []
    var iconImages: [UIImage] = []
    private var selectedIconItem: String?
    
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
        case .colorItems, .iconItems, .bigIconItems:
            tableView.register(UINib(nibName: OACollectionSingleLineTableViewCell.reuseIdentifier, bundle: nil),
                               forCellReuseIdentifier: OACollectionSingleLineTableViewCell.reuseIdentifier)
        case .colorizationPaletteItems, .terrainPaletteItems:
            tableView.register(UINib(nibName: OATwoIconsButtonTableViewCell.reuseIdentifier, bundle: nil),
                               forCellReuseIdentifier: OATwoIconsButtonTableViewCell.reuseIdentifier)
        }
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = (collectionType == .colorizationPaletteItems || collectionType == .terrainPaletteItems)  ? .singleLine : .none
        tableView.backgroundColor = collectionType == .colorItems ? UIColor.groupBg : UIColor.viewBg
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
        }
    }
    
    // MARK: - Base UI
    
    override func getTitle() -> String {
        localizedString("shared_string_all_colors")
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_cancel")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        if collectionType == .colorItems {
            let addButton = UIBarButtonItem(image: UIImage(named: "ic_custom_add"),
                                            style: .plain,
                                            target: self,
                                            action: #selector(onRightNavbarButtonPressed))
            addButton.accessibilityLabel = localizedString("shared_string_add_color")
            return [addButton]
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
            let colorsSection = data.createNewSection()
            colorsSection.addRow(from: [
                kCellTypeKey: OACollectionSingleLineTableViewCell.reuseIdentifier
            ])
            colorCollectionIndexPath = IndexPath(row: Int(colorsSection.rowCount()) - 1, section: Int(data.sectionCount()) - 1)
        } else {
            let palettesSection = data.createNewSection()
            paletteItems?.asArray().forEach { paletteColor in
                if let color = paletteColor as? PaletteColor {
                    palettesSection.addRow(generateRowData(for: color))
                }
            }
        }
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
    
    override func sectionsCount() -> Int {
        Int(data.sectionCount())
    }
    
    override func rowsCount(_ section: Int) -> Int {
        Int(data.rowCount(UInt(section)))
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = data.item(for: indexPath)
        
        if item.cellType == OACollectionSingleLineTableViewCell.reuseIdentifier {
            if let cell = tableView.dequeueReusableCell(withIdentifier: OACollectionSingleLineTableViewCell.reuseIdentifier, for: indexPath) as? OACollectionSingleLineTableViewCell {
                if collectionType == .colorItems {
                    setupColorCollectionCell(cell)
                } else if collectionType == .iconItems || collectionType == .bigIconItems {
                    setupIconCollectionCell(cell)
                }
                cell.rightActionButtonVisibility(false)
                cell.anchorContent(.centerStyle)
                cell.collectionView.isScrollEnabled = false
                cell.useMultyLines = true
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
            cell.setCollectionHandler(colorCollectionHandler)
        }
    }
    
    private func setupIconCollectionCell(_ cell: OACollectionSingleLineTableViewCell) {
        if let iconHandler = IconCollectionHandler(data: [iconItems], collectionView: cell.collectionView) {
            iconHandler.delegate = self
            iconHandler.hostVC = self
            iconHandler.selectedIconColor = selectedIconColor
            iconHandler.regularIconColor = regularIconColor
            iconHandler.setScrollDirection(.vertical)
            
            if let selectedIconItem, let selectedIndex = iconItems.firstIndex(of: selectedIconItem) {
                iconHandler.setSelectedIndexPath(IndexPath(row: selectedIndex, section: 0))
            }
            
            cell.disableAnimationsOnStart = true
            
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
        }
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = data.item(for: indexPath)
        if item.key == "paletteColor" {
            if let palette = item.obj(forKey: "palette") as? PaletteColor {
                selectedPaletteItem = palette
                delegate?.selectPaletteItem(palette)
            }
            dismiss(animated: true)
        }
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
            self?.duplicateItem(fromContextMenu: indexPath)
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
                    self?.deleteItem(fromContextMenu: indexPath)
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
            self?.tableView.deleteRows(at: indexPathsToDelete, with: .automatic)
        } completion: { [weak self] _ in
            guard let weakself = self else { return }
            
            if removeCurrent {
                var newCurrentSelected: PaletteColor?
                if let colorsCollection = weakself.colorsCollection {
                    
                    if colorsCollection.isTerrainType() {
                        let terrainType = TerrainMode.TerrainTypeWrapper.valueOf(typeName: currentGradientPaletteColor.typeName)
                        if let defaultMode = TerrainMode.getDefaultMode(terrainType) {
                            newCurrentSelected = colorsCollection.getPaletteColor(byName: defaultMode.getKeyName())
                        }
                    } else {
                        newCurrentSelected = colorsCollection.getDefaultGradientPalette()
                    }
                }
                
                weakself.selectedPaletteItem = newCurrentSelected
                if let newCurrentSelected = newCurrentSelected,
                   let currentIndex = weakself.paletteItems?.index(ofObjectSync: newCurrentSelected) {
                    weakself.tableView.reloadRows(at: [IndexPath(row: Int(currentIndex), section: 0)], with: .automatic)
                }
            }
            weakself.tableView.reloadData()
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
                self?.tableView.insertRows(at: indexPathsToInsert, with: .automatic)
            } completion: { [weak self] _ in
                self?.tableView.reloadData()
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
                self?.tableView.reloadRows(at: indexPathsToUpdate, with: .automatic)
            } completion: { [weak self] _ in
                self?.tableView.reloadData()
            }
        }
    }
}
    
extension ItemsCollectionViewController: OACollectionCellDelegate {
    
    func onCollectionItemSelected(_ indexPath: IndexPath, collectionView: UICollectionView) {
        if collectionType == .iconItems || collectionType == .bigIconItems {
            selectedIconItem = iconItems[indexPath.row]
            if let selectedIconItem {
                iconsDelegate?.selectIconName(selectedIconItem)
            }
            dismiss(animated: true)
        } else {
            selectedColorItem = colorCollectionHandler?.getSelectedItem()
            if let selectedColorItem {
                delegate?.selectColorItem(selectedColorItem)
            }
        }
    }
    
    func reloadCollectionData() {
        if let colorCollectionIndexPath = colorCollectionIndexPath {
            tableView.reloadRows(at: [colorCollectionIndexPath], with: .none)
        }
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
        guard let delegate = delegate, let colorCollectionIndexPath = colorCollectionIndexPath else { return }
        
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
                if let editPath = editColorIndexPath {
                    colorCollectionHandler?.replaceOldColor(editPath)
                } else {
                    colorCollectionHandler?.replaceOldColor(IndexPath(row: 0, section: 0))
                }
            }
        }
    }
}

// MARK: - OAColorPickerViewControllerDelegate

extension ItemsCollectionViewController: OAColorPickerViewControllerDelegate {
    
    func onColorPickerDisappear(_ colorPicker: OAColorPickerViewController) {
        isStartedNewColorAdding = false
        editColorIndexPath = nil
    }
}
