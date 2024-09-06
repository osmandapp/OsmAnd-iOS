//
//  IconCollectionHandler.swift
//  OsmAnd Maps
//
//  Created by Mak Kojin on 23.08.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class IconCollectionHandler: OABaseCollectionHandler, OAIconCollectionDelegate {
    
    private var selectedIndexPath: IndexPath?
    private var defaultIndexPath: IndexPath?
    private var iconNamesData = [[String]]()
    var iconImagesData = [[UIImage]]()
    var roundedSquareCells = false
    var customTitle = ""
    
    weak var hostVC: OASuperViewController?
    
    var selectedIconColor: UIColor?
    var regularIconColor: UIColor?
    var cornerRadius: Double = -1
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
    
    func getIconSize() -> CGFloat{
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
        var newData = [[String]]()
        for i in 0...data.count - 1 {
            if let icons = data[i] as? [String] {
                newData.append(icons)
            }
        }
        self.iconNamesData = newData
    }
    
    override func itemsCount(_ section: Int) -> Int {
        iconNamesData[section].count
    }
    
    override func getCollectionViewCell(_ indexPath: IndexPath) -> UICollectionViewCell {
        let cell: OAIconsCollectionViewCell = getCollectionView().dequeueReusableCell(withReuseIdentifier: getCellIdentifier(), for: indexPath) as! OAIconsCollectionViewCell
        
        cell.iconWidthConstraint.constant = getItemSize().width
        cell.iconHeightConstraint.constant = getItemSize().height
        cell.iconWidthConstraint.constant = getIconSize()
        cell.iconHeightConstraint.constant = getIconSize()
        
        if iconImagesData.count > 0 {
            cell.iconImageView.image = iconImagesData[indexPath.section][indexPath.row]
        } else {
            let iconName = iconNamesData[indexPath.section][indexPath.row]
            cell.iconImageView.image = UIImage.templateImageNamed(iconName)
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
        if cornerRadius != -1 {
            cell.iconView.layer.cornerRadius = cornerRadius
            cell.backView.layer.cornerRadius = cornerRadius
        } else {
            cell.iconView.layer.cornerRadius = cell.iconView.frame.size.height/2;
            cell.backView.layer.cornerRadius = cell.backView.frame.size.height/2;
        }
        return cell
    }
    
    override func sectionsCount() -> Int {
        iconNamesData.count
    }
    
    func openAllIconsScreen() {
        if let hostVC {
            
            var vc: OAColorCollectionViewController?
            if !iconImagesData.isEmpty {
                vc = OAColorCollectionViewController(collectionType: EOAColorCollectionTypeBigIconItems, items: iconNamesData[0], selectedItem: getSelectedItem())
                vc?.setImages(iconImagesData[0])
            } else {
                vc = OAColorCollectionViewController(collectionType: EOAColorCollectionTypeIconItems, items: iconNamesData[0], selectedItem: getSelectedItem())
            }
            vc?.customTitle = customTitle
            
            if let vc {
                vc.iconsDelegate = self
                if let selectedIconColor {
                    vc.selectedIconColor = selectedIconColor
                }
                if let regularIconColor {
                    vc.regularIconColor = regularIconColor
                }
                hostVC.showModalViewController(vc)
            }
        }
    }
    
    func getSelectedItem() -> Any {
        if let selectedIndexPath {
            return iconNamesData[selectedIndexPath.section][selectedIndexPath.row]
        }
        return iconNamesData[0][0]
    }
    
    // MARK: - OAIconCollectionDelegate
    
    func selectIconName(_ iconName: String) {
        if let selectedIndex = iconNamesData[0].index(of: iconName) {
            let selectedIndexPath = IndexPath(row: selectedIndex, section: 0)
            setSelectedIndexPath(selectedIndexPath)
            getCollectionView()?.reloadData()
            getCollectionView().scrollToItem(at: selectedIndexPath, at: .centeredHorizontally, animated: false)
        }
    }
}
