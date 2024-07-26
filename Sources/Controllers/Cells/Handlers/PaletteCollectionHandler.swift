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
    private var defaultIndexPath: IndexPath?
    private var data = [[PaletteColor]]()
    private var roundedSquareImage: UIImage?

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

    override func getDefaultIndexPath() -> IndexPath? {
        defaultIndexPath
    }

    override func setSelectedIndexPath(_ selectedIndexPath: IndexPath) {
        self.selectedIndexPath = selectedIndexPath
    }

    override func generateData(_ data: [[Any]]) {
        var newData = [[PaletteColor]]()
        for i in 0...data.count - 1 {
            let items = data[i]
            if let palettes = items as? [PaletteColor] {
                newData.append(palettes)

                if let gradients = palettes as? [PaletteGradientColor] {
                    var defaultGradient = gradients.first(where: {
                        $0.paletteName == TerrainMode.defaultKey
                    })
                    if defaultGradient == nil {
                        defaultGradient = gradients.first(where: {
                            $0.typeName == TerrainType.height.name && $0.paletteName == TerrainMode.altitudeDefaultKey
                        })
                    }
                    if defaultGradient == nil {
                        defaultGradient = gradients.first(where: {
                            $0.typeName == $0.paletteName
                        })
                    }
                    if let defaultGradient, let index = gradients.firstIndex(of: defaultGradient) {
                        defaultIndexPath = IndexPath(row: index, section: i)
                    }
                }
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

        cell.selectionView.layer.cornerRadius = getSelectionRadius()
        cell.backgroundImageView.tintColor = nil
        cell.backgroundImageView.layer.cornerRadius = getImageRadius()

        if roundedSquareImage == nil {
            roundedSquareImage = createRoundedSquareImage(size: cell.backgroundImageView.frame.size,
                                                          cornerRadius: cell.backgroundImageView.layer.cornerRadius)
        }
        cell.backgroundImageView.image = roundedSquareImage
        let paletteColor = data[indexPath.section][indexPath.row]
        if cell.backgroundImageView.tag != Int(paletteColor.id) {
            cell.backgroundImageView.gradated(createGradientPoints(paletteColor))
            cell.backgroundImageView.tag = Int(paletteColor.id)
        }
        
        if indexPath == selectedIndexPath {
            cell.selectionView.layer.borderWidth = 2
            cell.selectionView.layer.borderColor = UIColor.buttonBgColorPrimary.cgColor
        } else {
            cell.selectionView.layer.borderWidth = 0
            cell.selectionView.layer.borderColor = UIColor.clear.cgColor
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
