//
//  ChipsCollectionHandler.swift
//  OsmAnd
//
//  Created by Max Kojin on 25/02/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ChipsCollectionHandler: OABaseCollectionHandler {
    
    static let folderCellHeight = 30.0
    static let folderCellSidePadding = 10.0
    
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
        CGSize(width: 0, height: Self.folderCellHeight) // 0 = automatic
    }
    
    override func calculateItemSize(for indexPath: IndexPath!) -> CGSize {
        let title = titles[indexPath.row]
        let attributes = [NSAttributedString.Key.font: UIFont.scaledSystemFont(ofSize: 15.0)]
        let labelSize = title.size(withAttributes: attributes)
        let width = labelSize.width + 2 * Self.folderCellSidePadding
        return CGSize(width: width, height: Self.folderCellHeight)
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
            cell.imageView.tintColor = .iconColorActive
            
            if iconNames.count > index && !iconNames[index].isEmpty {
                cell.showImage(true)
                cell.imageView.image = UIImage.templateImageNamed(iconNames[index])
            } else {
                cell.showImage(false)
                cell.imageView.image = nil
            }
            
            if index == selectedIndexPath.row {
                cell.layer.backgroundColor = UIColor.buttonBgColorTap.cgColor
                cell.titleLabel.textColor = .buttonTextColorPrimary
                cell.imageView.tintColor = .buttonTextColorPrimary
            } else {
                cell.layer.backgroundColor = UIColor.buttonBgColorTertiary.cgColor
                cell.titleLabel.textColor = .buttonTextColorSecondary
                cell.imageView.tintColor = .buttonTextColorSecondary
            }
            
            if cell.isDirectionRTL() {
                cell.contentView.transform = CGAffineTransform(scaleX: -1, y: 1)
            }

            return cell
        }
        return UICollectionViewCell()
    }
}
