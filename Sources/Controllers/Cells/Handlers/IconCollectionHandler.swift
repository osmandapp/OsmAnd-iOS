//
//  IconCollectionHandler.swift
//  OsmAnd Maps
//
//  Created by Mak Kojin on 23.08.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class IconCollectionHandler: OABaseCollectionHandler {
    
    var iconImagesData = [[UIImage]]()
    var roundedSquareCells = false
    var customTitle = ""
    var selectedIconColor: UIColor?
    var regularIconColor: UIColor?
    var innerViewCornerRadius: Double = -1
    var strokeCornerRadius: Double = -1
    
    weak var hostVC: OASuperViewController?
    weak var hostCell: OAIconsPaletteCell?
    
    private var selectedIndexPath: IndexPath?
    private var defaultIndexPath: IndexPath?
    private var iconNamesData = [[String]]()
    private var cellSize: Double?
    private var iconSize: Double?
    
    func setItemSize(size: CGFloat) {
        cellSize = size
    }
    
    override func getItemSize() -> CGSize {
        if let cellSize {
            return CGSize(width: cellSize, height: cellSize)
        } else {
            return super.getItemSize()
        }
    }
    
    func setIconSize(size: CGFloat) {
        iconSize = size
    }
    
    func getIconSize() -> CGFloat {
        iconSize ?? 30
    }
    
    override func getCellIdentifier() -> String {
        OAIconsCollectionViewCell.reuseIdentifier
    }
    
    override func getSelectedIndexPath() -> IndexPath? {
        selectedIndexPath
    }
    
    override func getDefaultIndexPath() -> IndexPath? {
        defaultIndexPath
    }
    
    override func setSelectedIndexPath(_ selectedIndexPath: IndexPath) {
        self.selectedIndexPath = selectedIndexPath
    }
    
    override func generateData(_ data: [[Any]]) {
        if let iconNames = data as? [[String]] {
            iconNamesData = iconNames
        }
    }
    
    override func sectionsCount() -> Int {
        iconNamesData.count
    }
    
    override func itemsCount(_ section: Int) -> Int {
        iconNamesData[section].count
    }
    
    override func getCollectionViewCell(_ indexPath: IndexPath) -> UICollectionViewCell {
        let cell: OAIconsCollectionViewCell = getCollectionView().dequeueReusableCell(withReuseIdentifier: getCellIdentifier(), for: indexPath) as! OAIconsCollectionViewCell
        
        let itemSize = getItemSize()
        let iconSize = getIconSize()
        cell.iconWidthConstraint.constant = itemSize.width
        cell.iconHeightConstraint.constant = itemSize.height
        cell.iconWidthConstraint.constant = iconSize
        cell.iconHeightConstraint.constant = iconSize
        
        if !iconImagesData.isEmpty && !iconImagesData[indexPath.section].isEmpty {
            cell.iconImageView.image = iconImagesData[indexPath.section][indexPath.row]
        } else if !iconNamesData.isEmpty && !iconNamesData[indexPath.section].isEmpty {
            let iconName = iconNamesData[indexPath.section][indexPath.row]
            if let icon = UIImage.templateImageNamed(iconName) {
                cell.iconImageView.image = icon
            } else {
                cell.iconImageView.image = OAUtilities.getMxIcon(iconName.lowercased())
            }
        }
        if indexPath == selectedIndexPath {
            cell.iconImageView.tintColor = selectedIconColor
            cell.backView.layer.borderColor = selectedIconColor?.cgColor
            cell.backView.layer.borderWidth = 2
        } else {
            cell.iconImageView.tintColor = regularIconColor
            cell.backView.layer.borderColor = UIColor.clear.cgColor
            cell.backView.layer.borderWidth = 0
        }
        if innerViewCornerRadius != -1 && strokeCornerRadius != -1 {
            cell.iconView.layer.cornerRadius = innerViewCornerRadius
            cell.backView.layer.cornerRadius = strokeCornerRadius
        } else {
            cell.iconView.layer.cornerRadius = cell.iconView.frame.size.height / 2
            cell.backView.layer.cornerRadius = cell.backView.frame.size.height / 2
        }
        return cell
    }
    
    func openAllIconsScreen() {
        guard let hostVC else { return }
        let vc = ItemsCollectionViewController(collectionType: iconImagesData.isEmpty ? .iconItems : .bigIconItems, items: iconNamesData[0], selectedItem: getSelectedItem())
        if !iconImagesData.isEmpty {
            vc.iconImages = iconImagesData[0]
        }
        vc.customTitle = customTitle
        vc.iconsDelegate = self
        if let selectedIconColor {
            vc.selectedIconColor = selectedIconColor
        }
        if let regularIconColor {
            vc.regularIconColor = regularIconColor
        }
        hostVC.showModalViewController(vc)
    }
    
    func getSelectedItem() -> Any {
        if let selectedIndexPath, !iconNamesData.isEmpty, !iconNamesData[selectedIndexPath.section].isEmpty {
            return iconNamesData[selectedIndexPath.section][selectedIndexPath.row]
        }
        return iconNamesData[0][0]
    }
    
    func buildTopButtonContextMenu() -> UIMenu? {
        nil
    }
}

extension IconCollectionHandler: IconsCollectionViewControllerDelegate {
    
    func selectIconName(_ iconName: String) {
        guard let selectedIndex = iconNamesData[0].firstIndex(of: iconName) else { return }
        let selectedIndexPath = IndexPath(row: selectedIndex, section: 0)
        setSelectedIndexPath(selectedIndexPath)
        getCollectionView()?.reloadData()
        getCollectionView().scrollToItem(at: selectedIndexPath, at: .centeredHorizontally, animated: false)
        onItemSelected(selectedIndexPath, collectionView: getCollectionView())
    }
}
