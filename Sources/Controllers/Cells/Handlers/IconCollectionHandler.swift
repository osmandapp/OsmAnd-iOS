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
    private var data = [[String]]()
    private var roundedSquareImage: UIImage?
    
    weak var hostVC: OASuperViewController?
    
    var selectedIconColor: UIColor?
    var regularIconColor: UIColor?
    private var cornerRadius: Double?
    private var cellSize: Double?
    
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
        self.data = newData
    }
    
    override func insertItem(_ newItem: Any, at indexPath: IndexPath) {
        if let newItem = newItem as? String, data.count > indexPath.section, (indexPath.row == 0 || data[indexPath.section].count > indexPath.row - 1) {
            data[indexPath.section].insert(newItem, at: indexPath.row)
        }
        if let collectionView = getCollectionView() {
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: [indexPath])
            } completion: { _ in
                collectionView.reloadData()
            }
        }
    }
    
    override func replaceItem(_ newItem: Any, at indexPath: IndexPath) {
        if let newItem = newItem as? String, data.count > indexPath.section, data[indexPath.section].count > indexPath.row {
            data[indexPath.section][indexPath.row] = newItem
        }
        if let collectionView = getCollectionView() {
            collectionView.reloadItems(at: [indexPath])
            collectionView.reloadData()
        }
    }
    
    override func removeItem(_ indexPath: IndexPath) {
        var deleteCurrent = false
        if data.count > indexPath.section, data[indexPath.section].count > indexPath.row {
            data[indexPath.section].remove(at: indexPath.row)
            if let selectedIndexPath {
                if let defaultIndexPath, defaultIndexPath.row > indexPath.row {
                    self.defaultIndexPath = IndexPath(row: defaultIndexPath.row - 1, section: defaultIndexPath.section)
                }
                if selectedIndexPath.row > indexPath.row {
                    self.selectedIndexPath = IndexPath(row: selectedIndexPath.row - 1, section: selectedIndexPath.section)
                } else if indexPath == selectedIndexPath {
                    deleteCurrent = true
                }
            }
            if let collectionView = getCollectionView() {
                collectionView.performBatchUpdates {
                    collectionView.deleteItems(at: [indexPath])
                } completion: { [weak self] _ in
                    guard let self else { return }
                    
                    collectionView.reloadData()
                    if deleteCurrent, let defaultIndexPath = self.defaultIndexPath, let selectedIdxPath = self.selectedIndexPath {
                        let indexPathsToUpdate = [selectedIdxPath, defaultIndexPath]
                        self.selectedIndexPath = defaultIndexPath
                        collectionView.reloadItems(at: indexPathsToUpdate)
                    }
                }
            }
        }
    }
    
    override func removeItems(_ indexPaths: [IndexPath]) {
        var deletedIndexPaths = [IndexPath]()
        var deleteCurrent = false
        indexPaths.forEach {
            if data.count > $0.section && data[$0.section].count > $0.row {
                data[$0.section].remove(at: $0.row)
                deletedIndexPaths.append($0)
                if let defaultIndexPath, defaultIndexPath.row > $0.row {
                    self.defaultIndexPath = IndexPath(row: defaultIndexPath.row - 1, section: defaultIndexPath.section)
                }
                if let selectedIndexPath {
                    if selectedIndexPath.row > $0.row {
                        self.selectedIndexPath = IndexPath(row: selectedIndexPath.row - 1, section: selectedIndexPath.section)
                    } else if $0 == selectedIndexPath {
                        deleteCurrent = true
                    }
                }
            }
        }
        if !deletedIndexPaths.isEmpty, let collectionView = getCollectionView() {
            collectionView.performBatchUpdates {
                collectionView.deleteItems(at: deletedIndexPaths)
            } completion: { [weak self] _ in
                guard let self else { return }
                
                collectionView.reloadData()
                if deleteCurrent, let defaultIndexPath {
                    let indexPathsToUpdate = [self.selectedIndexPath!, defaultIndexPath]
                    self.selectedIndexPath = defaultIndexPath
                    collectionView.reloadItems(at: indexPathsToUpdate)
                }
            }
        }
    }
    
    override func itemsCount(_ section: Int) -> Int {
        data[section].count
    }
    
    override func getCollectionViewCell(_ indexPath: IndexPath) -> UICollectionViewCell {
        let cell: OAIconsCollectionViewCell = getCollectionView().dequeueReusableCell(withReuseIdentifier: getCellIdentifier(), for: indexPath) as! OAIconsCollectionViewCell
        let iconName = data[indexPath.section][indexPath.row]
        cell.iconImageView.image = UIImage.templateImageNamed(iconName)
        if indexPath == selectedIndexPath {
            cell.iconImageView.tintColor = selectedIconColor
            cell.backView.layer.borderColor = selectedIconColor?.cgColor
            cell.backView.layer.borderWidth = 2
        } else {
            cell.iconImageView.tintColor = regularIconColor
            cell.backView.layer.borderColor = UIColor.clear.cgColor
            cell.backView.layer.borderWidth = 0
        }
        if let cornerRadius {
            cell.iconView.layer.cornerRadius = cornerRadius
            cell.backView.layer.cornerRadius = cornerRadius
        } else {
            cell.iconView.layer.cornerRadius = cell.iconView.frame.size.height/2;
            cell.backView.layer.cornerRadius = cell.backView.frame.size.height/2;
        }
        return cell
    }
    
    override func sectionsCount() -> Int {
        data.count
    }
    
    func openAllIconsScreen() {
        if let hostVC {
            let vc = OAColorCollectionViewController(collectionType: EOAColorCollectionTypeIconItems, items: data[0], selectedItem: getSelectedItem())
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
    
    func getSelectedItem() -> String {
        if let selectedIndexPath {
            return data[selectedIndexPath.section][selectedIndexPath.row]
        }
        return data[0][0]
    }
    
    // MARK: - OAIconCollectionDelegate
    
    func selectIconItem(_ iconItem: String) {
        if let selectedIndex = data[0].index(of: iconItem) {
            let selectedIndexPath = IndexPath(row: selectedIndex, section: 0)
            setSelectedIndexPath(selectedIndexPath)
            getCollectionView()?.reloadData()
            getCollectionView().scrollToItem(at: selectedIndexPath, at: .centeredHorizontally, animated: false)
        }
    }
}
