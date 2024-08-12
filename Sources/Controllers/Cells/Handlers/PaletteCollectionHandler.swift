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
        PaletteCollectionViewCell.reuseIdentifier
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

    override func insertItem(_ newItem: Any, at indexPath: IndexPath) {
        if let newItem = newItem as? PaletteColor, data.count > indexPath.section && (indexPath.row == 0 || data[indexPath.section].count > indexPath.row - 1) {
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
        if let newItem = newItem as? PaletteColor, data.count > indexPath.section && data[indexPath.section].count > indexPath.row {
            data[indexPath.section][indexPath.row] = newItem
        }
        if let collectionView = getCollectionView() {
            collectionView.reloadItems(at: [indexPath])
            collectionView.reloadData()
        }
    }

    override func removeItem(_ indexPath: IndexPath) {
        var deleteCurrent = false
        if data.count > indexPath.section && data[indexPath.section].count > indexPath.row {
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
                    if deleteCurrent, let defaultIndexPath = self.defaultIndexPath {
                        let indexPathsToUpdate = [self.selectedIndexPath!, defaultIndexPath]
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
        indexPaths.forEach { [weak self] in
            guard let self else { return }

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
        let cell: PaletteCollectionViewCell = getCollectionView().dequeueReusableCell(withReuseIdentifier: getCellIdentifier(), for: indexPath) as! PaletteCollectionViewCell

        if roundedSquareImage == nil {
            roundedSquareImage = createRoundedSquareImage(size: cell.backgroundImageView.frame.size,
                                                          cornerRadius: cell.backgroundImageView.layer.cornerRadius)
        }
        cell.backgroundImageView.image = roundedSquareImage
        let paletteColor = data[indexPath.section][indexPath.row]
        if cell.backgroundImageView.tag != Int(paletteColor.id) {
            cell.backgroundImageView.gradated(Self.createGradientPoints(paletteColor))
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
    
    @objc static func applyGradient(to imageView: UIImageView, with palette: PaletteColor) {
        let gradientPoints = Self.createGradientPoints(palette)
        imageView.gradated(gradientPoints)
    }

    @objc static func createDescriptionForPalette(palette: PaletteColor) -> String {
        guard let gradientPalette = palette as? PaletteGradientColor else {
            return "Invalid palette type"
        }
        return gradientPalette.colorPalette.colorValues.compactMap { "\($0.val)" }.joined(separator: " • ")
    }

    private static func createGradientPoints(_ palette: PaletteColor) -> [GradientPoint] {
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
