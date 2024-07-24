//
//  PaletteCollectionHandler.swift
//  OsmAnd Maps
//
//  Created by Skalii on 17.07.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

final class PaletteCollectionHandler: OABaseCollectionHandler {

    private var selectedIndexPath: IndexPath?
    private var data = [[PaletteColor]]()

    override func getCellIdentifier() -> String {
        OAColorsCollectionViewCell.getIdentifier()
    }

    override func getSelectionRadius() -> CGFloat {
        9
    }

    override func getImageRadius() -> CGFloat {
        3
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
        let cell: OAColorsCollectionViewCell = getCollectionView().dequeueReusableCell(withReuseIdentifier: OAColorsCollectionViewCell.reuseIdentifier, for: indexPath) as! OAColorsCollectionViewCell
        if let colorView = cell.colorView {
            colorView.removeFromSuperview()
        }

        cell.backView.layer.cornerRadius = getSelectionRadius()
        cell.chessboardView.tintColor = nil
        cell.chessboardView.layer.cornerRadius = getImageRadius()
        cell.chessboardView.image = createRoundedSquareImage(size: cell.chessboardView.frame.size,
                                                             cornerRadius: cell.chessboardView.layer.cornerRadius)
        cell.chessboardView.gradated(gradientPoints: createGradientPoints(data[indexPath.section][indexPath.row]))
        
        if indexPath == selectedIndexPath {
            cell.backView.layer.borderWidth = 2
            cell.backView.layer.borderColor = UIColor.buttonBgColorPrimary.cgColor
        } else {
            cell.backView.layer.borderWidth = 0
            cell.backView.layer.borderColor = UIColor.clear.cgColor
        }
        return cell
    }

    override func sectionsCount() -> Int {
        data.count
    }

    private func createGradientPoints(_ palette: PaletteColor) -> [GradientPoint] {
        var gradientPoints = [GradientPoint]()
        if let gradientPalette = palette as? PaletteGradientColor {
            let colorValues = gradientPalette.colorPalette.colorValues
            let step = 1.0 / CGFloat(colorValues.count - 1)
            for i in 0...colorValues.count - 1 {
                let colorValue = colorValues[i]
                gradientPoints.append(GradientPoint(location: CGFloat(i) * step,
                                                    color: UIColor(argb: colorValue.clr)))
            }
        }
        return gradientPoints
    }

    private func createRoundedSquareImage(size: CGSize, cornerRadius: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            UIColor.clear.setFill()
            path.fill()
        }
        return image
    }
}
