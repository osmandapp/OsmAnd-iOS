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
    private var data = [[PaletteItemGradient]]()

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

    func setSelectionItem(_ item: PaletteItemGradient?) {
        if let indexPath = indexPath(for: item) {
            selectedIndexPath = indexPath
        }
    }

    override func generateData(_ data: [[Any]]) {
        var newData = [[PaletteItemGradient]]()
        defaultIndexPath = nil
        for i in data.indices {
            let items = data[i]
            if let palettes = items as? [PaletteItemGradient] {
                newData.append(palettes)

                if defaultIndexPath == nil, let index = palettes.firstIndex(where: { $0.isDefault }) {
                    defaultIndexPath = IndexPath(row: index, section: i)
                }
            }
        }
        self.data = newData
    }

    override func insertItem(_ newItem: Any, at indexPath: IndexPath) {
        if let newItem = newItem as? PaletteItemGradient, data.count > indexPath.section, (indexPath.row == 0 || data[indexPath.section].count > indexPath.row - 1) {
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
        if let newItem = newItem as? PaletteItemGradient, data.count > indexPath.section, data[indexPath.section].count > indexPath.row {
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
                if deleteCurrent, let defaultIndexPath, let selectedIndexPath = self.selectedIndexPath {
                    let indexPathsToUpdate = [selectedIndexPath, defaultIndexPath]
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
        let cell = getCollectionView().dequeueReusableCell(withReuseIdentifier: getCellIdentifier(), for: indexPath)
        guard let cell = cell as? PaletteCollectionViewCell else { return cell }
        cell.backgroundImageView.layer.cornerRadius = 3
        cell.backgroundImageView.gradated(Self.createGradientPoints(data[indexPath.section][indexPath.row].getColorPalette()))

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

    @objc static func applyGradient(to imageView: UIImageView, with colorPalette: OsmAndShared.ColorPalette) {
        imageView.gradated(Self.createGradientPoints(colorPalette))
    }

    @objc static func createDescriptionForPalette(_ paletteItem: PaletteItemGradient) -> String {
        let fileType = paletteItem.properties.fileType
        return paletteItem.points.map {
            GradientFormatter.formatSimpleValue(value: $0.value, fileType: fileType)
        }.joined(separator: " • ")
    }

    private static func createGradientPoints(_ colorPalette: OsmAndShared.ColorPalette) -> [GradientPoint] {
        let colorValues = colorPalette.colors.compactMap { $0 as? OsmAndShared.ColorPalette.ColorValue }
        guard !colorValues.isEmpty else { return [] }
        if colorValues.count == 1 {
            let color = UIColor(argb: Int(colorValues[0].clr))
            return [GradientPoint(location: 0, color: color), GradientPoint(location: 1, color: color)]
        }

        var gradientPoints = [GradientPoint]()
        let step = 1.0 / CGFloat(colorValues.count - 1)
        for i in 0...colorValues.count - 1 {
            let colorValue = colorValues[i]
            gradientPoints.append(GradientPoint(location: CGFloat(i) * step, color: UIColor(argb: Int(colorValue.clr))))
        }

        return gradientPoints
    }

    private func indexPath(for item: PaletteItemGradient?) -> IndexPath? {
        guard let item else { return nil }
        for section in data.indices {
            if let row = data[section].firstIndex(where: { $0.id == item.id }) {
                return IndexPath(row: row, section: section)
            }
        }
    
        return nil
    }
}
