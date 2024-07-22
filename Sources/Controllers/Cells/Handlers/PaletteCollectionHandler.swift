//
//  PaletteCollectionHandler.swift
//  OsmAnd Maps
//
//  Created by Skalii on 17.07.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

protocol PaletteColorsCollectionCellDelegate: OACollectionCellDelegate {
    
}

final class PaletteCollectionHandler: OABaseCollectionHandler {

    private var selectedIndexPath: IndexPath?
    private var data = [[PaletteColor]]()

    override func getCellIdentifier() -> String {
        OAColorsCollectionViewCell.getIdentifier()
    }

    override func getSelectedIndexPath() -> IndexPath? {
        selectedIndexPath
    }

    override func setSelectedIndexPath(_ selectedIndexPath: IndexPath) {
        self.selectedIndexPath = selectedIndexPath
    }

    override func generateData(_ data: [[Any]]) {
        var newData = [[PaletteColor]]()
        for items in data {
            if let palettes = items as? [PaletteColor] {
                newData.append(palettes)
            }
        }
        self.data = newData
    }

    override func addItem(_ indexPath: IndexPath, newItem: Any) {
        if let newItem = newItem as? PaletteColor, data.count > indexPath.section && (indexPath.row == 0 || data[indexPath.section].count > indexPath.row - 1) {
            data[indexPath.section].insert(newItem, at: indexPath.row)
        }
    }

    override func removeItem(_ indexPath: IndexPath) {
        if data.count > indexPath.section && data[indexPath.section].count > indexPath.row {
            data[indexPath.section].remove(at: indexPath.row)
        }
    }

    override func itemsCount(_ section: Int) -> Int {
        data[section].count
    }

    override func getCollectionViewCell(_ indexPath: IndexPath) -> UICollectionViewCell {
        let colorValue = data[indexPath.section][indexPath.row].color
        let cell: OAColorsCollectionViewCell = getCollectionView().dequeueReusableCell(withReuseIdentifier: OAColorsCollectionViewCell.reuseIdentifier, for: indexPath) as! OAColorsCollectionViewCell
        
        cell.colorView.layer.borderWidth = 0
        let color = colorFromARGB(colorValue)
        cell.colorView.backgroundColor = color
        cell.chessboardView.image = UIImage.templateImageNamed("bg_color_chessboard_pattern")
        cell.chessboardView.tintColor = colorFromRGB(colorValue)
        
        if indexPath == selectedIndexPath {
            cell.backView.layer.borderWidth = 2
            cell.backView.layer.borderColor = UIColor.iconColorActive.cgColor
        } else {
            cell.backView.layer.borderWidth = 0
            cell.backView.layer.borderColor = UIColor.clear.cgColor
        }
        return cell
    }

    override func sectionsCount() -> Int {
        data.count
    }
}
