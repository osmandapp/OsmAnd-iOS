//
//  FavoritesChangeAppearanceViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 29.09.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class FavoritesChangeAppearanceViewController: OABaseNavbarViewController {
    private struct Appearance {
        var color: Int32?
        var iconName: String?
        var backgroundIconName: String?
    }

    var onApply: ((UIColor?, String?, String?) -> Void)?
    var onClose: (() -> Void)?

    private let appearanceCollection: OAGPXAppearanceCollection = .sharedInstance()
    private let iconHandler = PoiIconCollectionHandler(isFavoriteList: true)
    private let backgroundIconNames = OAFavoritesHelperBridge.shared().backgroundIconNames()
    private let initialAppearance: Appearance

    private var appearance: Appearance

    private lazy var colorHandler: OAColorCollectionHandler = .init(data: [appearanceCollection.getAvailableColorsSortingByLastUsed() ?? []], isFavoriteList: false)
    private lazy var shapeHandler = ShapesCollectionHandler(backgroundIconNames: backgroundIconNames, isFavoriteList: true)

    private var hasChanges: Bool {
        (appearance.color != nil && appearance.color != initialAppearance.color) || (appearance.iconName != nil && appearance.iconName != initialAppearance.iconName) || (appearance.backgroundIconName != nil && appearance.backgroundIconName != initialAppearance.backgroundIconName)
    }

    private var previewColor: UIColor {
        appearance.color.map { UIColor(argb: Int($0)) } ?? OADefaultFavorite.getDefaultColor()
    }

    init(points: [OAFavoritePointBridgeItem]) {
        let colors = Set(points.map { Int32(truncatingIfNeeded: $0.color.toARGBNumber()) })
        let icons = Set(points.map(\.iconName))
        let shapes = Set(points.map(\.backgroundIconName))
        initialAppearance = Appearance(color: colors.count == 1 ? colors.first : nil, iconName: icons.count == 1 ? icons.first : nil, backgroundIconName: shapes.count == 1 ? shapes.first : nil)
        appearance = initialAppearance
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        initTableData()
        setupHandlers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        iconHandler.setIconName(appearance.iconName ?? "")
        refreshAppearance()
    }

    override func registerCells() {
        addCell(OAColorsPaletteCell.reuseIdentifier)
        addCell(OAIconsPaletteCell.reuseIdentifier)
        addCell(OAShapesTableViewCell.reuseIdentifier)
    }

    override func getTitle() -> String {
        localizedString("change_appearance")
    }

    override func systemLeftBarButtonItem() -> UIBarButtonItem? {
        UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onLeftNavbarButtonPressed))
    }

    override func systemRightBarButtonItems() -> [UIBarButtonItem]? {
        [UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onRightNavbarButtonPressed))]
    }

    override func isNavbarSeparatorVisible() -> Bool {
        false
    }

    override func generateData() {
        tableData.clearAllData()

        let colorSection = tableData.createNewSection()
        let colorRow = colorSection.createNewRow()
        colorRow.cellType = OAColorsPaletteCell.reuseIdentifier
        colorRow.title = localizedString("shared_string_color")
        colorRow.descr = localizedString("original_color_description")

        let iconSection = tableData.createNewSection()
        let iconRow = iconSection.createNewRow()
        iconRow.cellType = OAIconsPaletteCell.reuseIdentifier
        iconRow.title = localizedString("shared_string_icon")
        iconRow.descr = localizedString("original_icon_description")

        let shapeSection = tableData.createNewSection()
        let shapeRow = shapeSection.createNewRow()
        shapeRow.cellType = OAShapesTableViewCell.reuseIdentifier
        shapeRow.title = localizedString("shared_string_shape")
        shapeRow.descr = localizedString("original_shape_description")
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell {
        let row = tableData.item(for: indexPath)
        guard let cellType = row.cellType, let cell = tableView.dequeueReusableCell(withIdentifier: cellType) as? OACollectionSingleLineTableViewCell else { return UITableViewCell() }
        cell.disableAnimationsOnStart = true
        cell.selectionStyle = .none
        if let cell = cell as? OAColorsPaletteCell {
            cell.hostVC = self
            cell.topLabel.text = row.title
            cell.descriptionLabel.text = row.descr
            cell.bottomButton.setTitle(localizedString("shared_string_all_colors"), for: .normal)
            colorHandler.setCollectionView(cell.collectionView)
            cell.setCollectionHandler(colorHandler)
            colorHandler.hostVCOpenColorPickerButton = cell.rightActionButton
            configureColorCell(cell)
        } else if let cell = cell as? OAIconsPaletteCell {
            cell.useMultyLines = false
            cell.forceScrollOnStart = true
            cell.hostVC = self
            cell.topLabel.font = .preferredFont(forTextStyle: .body)
            cell.topLabel.textColor = .textColorPrimary
            cell.topLabel.text = row.title
            cell.descriptionLabel.text = row.descr
            cell.bottomButton.setTitle(localizedString("shared_string_all_icons"), for: .normal)
            iconHandler.setCollectionView(cell.collectionView)
            cell.setCollectionHandler(iconHandler)
            configureIconCell(cell)
        } else if let cell = cell as? OAShapesTableViewCell {
            cell.shapesDelegate = self
            cell.titleLabel.text = row.title
            cell.descriptionLabel.text = row.descr
            cell.iconNames = backgroundIconNames.map { "bg_point_\($0)" }
            cell.contourIconNames = backgroundIconNames.map { "bg_point_\($0)_contour" }
            shapeHandler.setCollectionView(cell.collectionView)
            cell.setCollectionHandler(shapeHandler)
            configureShapeCell(cell)
        }

        return cell
    }

    override func onLeftNavbarButtonPressed() {
        if hasChanges {
            showUnsavedChangesSheet()
        } else {
            close()
        }
    }

    override func onRightNavbarButtonPressed() {
        let color = appearance.color != initialAppearance.color ? appearance.color : nil
        let iconName = appearance.iconName != initialAppearance.iconName ? appearance.iconName : nil
        let backgroundIconName = appearance.backgroundIconName != initialAppearance.backgroundIconName ? appearance.backgroundIconName : nil
        if color != nil, let colorItem = colorHandler.getSelectedItem() {
            appearanceCollection.selectColor(colorItem)
        }

        if let iconName {
            iconHandler.addIconToLastUsed(iconName)
        }

        onApply?(color.map { UIColor(argb: Int($0)) }, iconName, backgroundIconName)
        close()
    }

    private func close() {
        onClose?()
        dismiss(animated: true)
    }

    private func setupHandlers() {
        let color = Int32(truncatingIfNeeded: previewColor.toARGBNumber())
        let selectedColorItem = appearanceCollection.getColorItem(withValue: color)
        colorHandler.delegate = self
        colorHandler.hostVC = self
        if let selectedColorItem {
            colorHandler.setSelectionItem(selectedColorItem)
        }

        iconHandler.delegate = self
        iconHandler.hostVC = self
        iconHandler.customTitle = localizedString("profile_icon")
        iconHandler.regularIconColor = .iconColorSecondary
        iconHandler.setSpacing(spacing: 9)
        iconHandler.setIconName(appearance.iconName ?? "")
    }

    private func configureColorCell(_ cell: OAColorsPaletteCell) {
        let isUnchanged = appearance.color == nil
        cell.topButtonVisibility(true)
        cell.collectionStackViewVisibility(!isUnchanged)
        cell.descriptionLabelStackView.isHidden = !isUnchanged
        cell.bottomButtonStackView.isHidden = isUnchanged
        cell.separatorOffsetViewWidth.constant = isUnchanged ? 20 : 0
        configureMenuButton(cell.topButton, title: localizedString(isUnchanged ? "shared_string_unchanged" : "track_coloring_solid"), menu: colorMenu())
        cell.collectionView.reloadData()
    }

    private func configureIconCell(_ cell: OAIconsPaletteCell) {
        let isUnchanged = appearance.iconName == nil
        iconHandler.selectedIconColor = previewColor
        cell.topButtonVisibility(true)
        iconHandler.updateHostCellIfNoIconCategory(isUnchanged)
        let title = isUnchanged ? localizedString("shared_string_unchanged") : iconHandler.categoriesByKeyName[iconHandler.selectedCatagoryKey]?.translatedName ?? ""
        configureMenuButton(cell.topButton, title: title, menu: iconMenu())
        cell.collectionView.reloadData()
    }

    private func configureShapeCell(_ cell: OAShapesTableViewCell) {
        let isUnchanged = appearance.backgroundIconName == nil
        cell.topButtonVisibility(true)
        cell.valueLabel.isHidden = true
        cell.topRightOffset(4)
        cell.collectionStackViewVisibility(!isUnchanged)
        cell.descriptionLabelStackViewVisibility(isUnchanged)
        cell.separatorVisibility(isUnchanged)
        cell.currentColor = Int(previewColor.toARGBNumber())
        cell.currentIcon = appearance.backgroundIconName.flatMap { backgroundIconNames.firstIndex(of: $0) } ?? 0
        let title = appearance.backgroundIconName.map { localizedString("shared_string_\($0)") } ?? localizedString("shared_string_unchanged")
        configureMenuButton(cell.topButton, title: title, menu: shapeMenu())
        cell.collectionView.reloadData()
    }

    private func configureMenuButton(_ button: UIButton, title: String, menu: UIMenu) {
        let attributedTitle = NSMutableAttributedString(string: title + " ")
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "chevron.up.chevron.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))?.withRenderingMode(.alwaysTemplate)
        attributedTitle.append(NSAttributedString(attachment: attachment))
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.showsMenuAsPrimaryAction = true
        button.menu = menu
    }

    private func colorMenu() -> UIMenu {
        let unchanged = UIAction(title: localizedString("shared_string_unchanged"), state: appearance.color == nil ? .on : .off) { [weak self] _ in
            self?.appearance.color = nil
            self?.refreshAppearance()
        }

        let solid = UIAction(title: localizedString("track_coloring_solid"), state: appearance.color != nil ? .on : .off) { [weak self] _ in
            guard let self else { return }
            if let selectedColorItem = colorHandler.getSelectedItem() ?? appearanceCollection.defaultPointColorItem() {
                colorHandler.setSelectionItem(selectedColorItem)
                appearance.color = selectedColorItem.colorInt
            }
            refreshAppearance()
        }

        return UIMenu.composedMenu(from: [[unchanged], [solid]])
    }

    private func iconMenu() -> UIMenu {
        let unchanged = UIAction(title: localizedString("shared_string_unchanged"), state: appearance.iconName == nil ? .on : .off) { [weak self] _ in
            guard let self else { return }
            appearance.iconName = nil
            iconHandler.selectCategory(iconHandler.ORIGINAL_KEY)
            refreshAppearance()
        }

        var topActions: [UIMenuElement] = [unchanged]
        var categoryActions: [UIMenuElement] = []
        for category in iconHandler.categories where category.key != iconHandler.ORIGINAL_KEY {
            let action = UIAction(title: category.translatedName, state: appearance.iconName != nil && iconHandler.selectedCatagoryKey == category.key ? .on : .off) { [weak self] _ in
                self?.iconHandler.onMenuItemSelected(name: category.key)
            }

            if category.key == iconHandler.lastUsedKey {
                topActions.append(action)
            } else {
                categoryActions.append(action)
            }
        }

        return UIMenu.composedMenu(from: [topActions, categoryActions])
    }

    private func shapeMenu() -> UIMenu {
        let unchanged = UIAction(title: localizedString("shared_string_unchanged"), state: appearance.backgroundIconName == nil ? .on : .off) { [weak self] _ in
            self?.appearance.backgroundIconName = nil
            self?.refreshAppearance()
        }

        let shapes = backgroundIconNames.map { name in
            UIAction(title: localizedString("shared_string_\(name)"), state: appearance.backgroundIconName == name ? .on : .off) { [weak self] _ in
                self?.appearance.backgroundIconName = name
                self?.refreshAppearance()
            }
        }

        return UIMenu.composedMenu(from: [[unchanged], shapes])
    }

    private func refreshAppearance() {
        guard isViewLoaded else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for cell in tableView.visibleCells {
                if let cell = cell as? OAColorsPaletteCell {
                    configureColorCell(cell)
                } else if let cell = cell as? OAIconsPaletteCell {
                    configureIconCell(cell)
                } else if let cell = cell as? OAShapesTableViewCell {
                    configureShapeCell(cell)
                }
            }

            tableView.performBatchUpdates(nil)
        }
    }

    private func showUnsavedChangesSheet() {
        let alert = UIAlertController(title: localizedString("unsaved_changes"), message: localizedString("unsaved_changes_will_be_lost"), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_discard_changes"), style: .destructive) { [weak self] _ in
            self?.close()
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        alert.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        present(alert, animated: true)
    }
}

extension FavoritesChangeAppearanceViewController: OACollectionCellDelegate {
    func onCollectionItemSelected(_ indexPath: IndexPath, selectedItem: Any?, collectionView: UICollectionView, shouldDismiss: Bool) {
        if collectionView === colorHandler.getCollectionView() {
            appearance.color = (selectedItem as? PaletteItemSolid ?? colorHandler.getSelectedItem())?.colorInt
        } else if collectionView === iconHandler.getCollectionView(), let iconName = iconHandler.getSelectedItem() as? String, !iconName.isEmpty {
            appearance.iconName = iconName
        }

        refreshAppearance()
    }

    func reloadCollectionData() {
        refreshAppearance()
    }
}

extension FavoritesChangeAppearanceViewController: OAShapesTableViewCellDelegate {
    func iconChanged(_ tag: Int) {
        guard backgroundIconNames.indices.contains(tag) else { return }
        appearance.backgroundIconName = backgroundIconNames[tag]
        refreshAppearance()
    }
}
