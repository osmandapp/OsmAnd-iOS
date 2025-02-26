//
//  ChipsCollectionHandler.swift
//  OsmAnd
//
//  Created by Max Kojin on 25/02/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class ChipsCollectionHandler: OABaseCollectionHandler {
    
    var titles = [String]()
    var iconNames = [String]()
    private var selectedIndexPath = IndexPath()
    
    weak var hostCell: OAIconsPaletteCell?
    
    override func getCellIdentifier() -> String {
        OAFoldersCollectionViewCell.reuseIdentifier
    }
    
    override func getSelectedIndexPath() -> IndexPath? {
        selectedIndexPath
    }
    
    override func setSelectedIndexPath(_ selectedIndexPath: IndexPath) {
        self.selectedIndexPath = selectedIndexPath
    }
    
    override func getSelectedItem() -> Any {
        titles[selectedIndexPath.row]
    }
    
    override func getItemSize() -> CGSize {
        CGSize(width: 0, height: 30) // 0 = automatic
//        CGSize(width: 10, height: 30)
    }
    
    override func sectionsCount() -> Int {
        1
    }
    
    override func itemsCount(_ section: Int) -> Int {
        titles.count
    }

    override func getCollectionViewCell(_ indexPath: IndexPath) -> UICollectionViewCell {

        if let cell = getCollectionView().dequeueReusableCell(withReuseIdentifier: getCellIdentifier(), for: indexPath) as? OAFoldersCollectionViewCell {
            
            let index = indexPath.row
        
            cell.layer.cornerRadius = 9
            cell.titleLabel.text = titles[index]
            cell.imageView.tintColor = UIColor.iconColorActive
            
            if iconNames.count > index && !iconNames[index].isEmpty {
                cell.showImage(true)
                cell.imageView.image = UIImage.templateImageNamed(iconNames[index])
            } else {
                cell.showImage(false)
                cell.imageView.image = nil
            }
            
            if index == selectedIndexPath.row {
                cell.layer.backgroundColor = UIColor.buttonBgColorTap.cgColor
                cell.titleLabel.textColor = UIColor.buttonTextColorPrimary
                cell.imageView.tintColor = UIColor.buttonTextColorPrimary
            } else {
                cell.layer.backgroundColor = UIColor.buttonBgColorTertiary.cgColor
                cell.titleLabel.textColor = UIColor.buttonTextColorSecondary
                cell.imageView.tintColor = UIColor.buttonTextColorSecondary
            }
            
            if cell.isDirectionRTL() {
                cell.contentView.transform = CGAffineTransform(scaleX: -1, y: 1)
            }

            if cell.needsUpdateConstraints() {
                cell.setNeedsUpdateConstraints()
            }

            return cell
        }
        return UICollectionViewCell()
    }
}
