//
//  ColorsCollection.swift
//  OsmAnd Maps
//
//  Created by Skalii on 17.07.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc enum PaletteSortingMode: Int {
    case original
    case lastUsedTime
}

@objcMembers
class ColorsCollection: NSObject {

    static let collectionDeletedNotification = NSNotification.Name("CollectionDeletedPalettes")
    static let collectionCreatedNotification = NSNotification.Name("CollectionCreatedPalettes")
    static let collectionUpdatedNotification = NSNotification.Name("CollectionUpdatedPalettes")

    private var filesUpdatedObserver: NSObjectProtocol?
    private(set) var originalOrder: [PaletteColor] = []
    fileprivate(set) var lastUsedOrder: [PaletteColor] = []

    override init() {
        super.init()
        
        filesUpdatedObserver =
            NotificationCenter.default.addObserver(forName: ColorPaletteHelper.colorPalettesUpdatedNotification,
                                                   object: nil,
                                                   queue: .main) { [weak self] in
                guard let self else { return }
                self.onColorPalettesFilesUpdated($0)
        }
    }

    deinit {
        if let filesUpdatedObserver {
            NotificationCenter.default.removeObserver(filesUpdatedObserver)
        }
    }

    private func onColorPalettesFilesUpdated(_ notification: Notification) {
        guard let colorPaletteFiles = notification.object as? Dictionary<String, String> else { return }

        let deletedPalettes = onColorFilesDeleted(Array(colorPaletteFiles.filter {
            $0.value == ColorPaletteHelper.deletedFileKey
        }.keys))

        var createdPalettes = onColorFilesCreated(Array(colorPaletteFiles.filter {
            $0.value == ColorPaletteHelper.createdFileKey
        }.keys))
        createdPalettes.append(contentsOf: onColorFilesDuplicated(Array(colorPaletteFiles.filter {
            $0.value == ColorPaletteHelper.duplicatedFileKey
        }.keys)))

        let updatedPalettes = onColorFilesUpdated(Array(colorPaletteFiles.filter {
            $0.value == ColorPaletteHelper.updatedFileKey
        }.keys))

        saveColors()

        if !deletedPalettes.isEmpty {
            NotificationCenter.default.post(name: Self.collectionDeletedNotification, object: deletedPalettes)
        }
        if !createdPalettes.isEmpty {
            NotificationCenter.default.post(name: Self.collectionCreatedNotification, object: createdPalettes)
        }
        if !updatedPalettes.isEmpty {
            NotificationCenter.default.post(name: Self.collectionUpdatedNotification, object: updatedPalettes)
        }
    }

    func onColorFilesDeleted(_ colorPaletteFiles: [String]) -> [PaletteColor] {
        var paletteColors = [PaletteColor]()
        colorPaletteFiles.forEach {
            if let paletteColor = getPaletteColor(byFileName: $0) {
                if askRemoveColor(paletteColor, save: false) {
                    paletteColors.append(paletteColor)
                } else {
                    debugPrint("Color palette isn't removed from collection: \(colorPaletteFiles)")
                }
            } else {
                debugPrint("Сolor palette is not in collection: \(colorPaletteFiles)")
            }
        }
        return paletteColors
    }

    func onColorFilesCreated(_ colorPaletteFiles: [String]) -> [PaletteColor] {
        var paletteColors = [PaletteColor]()
        colorPaletteFiles.forEach {
            if let paletteColor = getPaletteColor(byFileName: $0, new: true),
               let newPaletteColor = addNewColor(paletteColor, updateLastUsedOrder: false, save: false) {
                paletteColors.append(newPaletteColor)
            }
        }
        return paletteColors
    }

    func onColorFilesUpdated(_ colorPaletteFiles: [String]) -> [PaletteColor] {
        var paletteColors = [PaletteColor]()
        colorPaletteFiles.forEach {
            if let paletteColor = getPaletteColor(byFileName: $0),
               let newPaletteColor = updateColor(paletteColor, newValue: nil, save: false) {
                paletteColors.append(newPaletteColor)
            }
        }
        return paletteColors
    }

    func onColorFilesDuplicated(_ colorPaletteFiles: [String]) -> [PaletteColor] {
        var paletteColors = [PaletteColor]()
        colorPaletteFiles.forEach {
            if let spaceIndex = $0.lastIndex(of: " ") {
                let suffix = String($0.suffix(from: spaceIndex))
                if let paletteColor = getPaletteColor(byFileName: $0.removeSuffix(suffix)) {
                    paletteColors.append(duplicateColor(paletteColor, save: false, suffix: String(suffix.dropLast(TXT_EXT.count))))
                } else {
                    debugPrint("Original color palette is not in collection: \(colorPaletteFiles)")
                }
            }
        }
        return paletteColors
    }

    func findPaletteColor(_ colorInt: Int) -> PaletteColor? {
        findPaletteColor(colorInt, registerIfNotFound: false)
    }

    func findPaletteColor(_ colorInt: Int, registerIfNotFound: Bool) -> PaletteColor? {
        for paletteColor in originalOrder where paletteColor.color == colorInt {
            return paletteColor
        }
        return registerIfNotFound ? addNewColor(colorInt, updateLastUsedOrder: false, save: true) : nil
    }

    func getColors(_ sortingMode: PaletteSortingMode) -> [PaletteColor] {
        sortingMode == .original ? originalOrder : lastUsedOrder
    }

    func setColors(_ originalColors: [PaletteColor], _ lastUsedColors: [PaletteColor]) {
        self.originalOrder.removeAll()
        self.lastUsedOrder.removeAll()
        self.originalOrder.append(contentsOf: originalColors)
        self.lastUsedOrder.append(contentsOf: lastUsedColors)
        saveColors()
    }

    func duplicateColor(_ paletteColor: PaletteColor, save: Bool, suffix: String? = nil) -> PaletteColor {
        let duplicate = paletteColor.duplicate(suffix)
        addColorDuplicate(&originalOrder, original: paletteColor, duplicate: duplicate)
        addColorDuplicate(&lastUsedOrder, original: paletteColor, duplicate: duplicate)
        if save {
            saveColors()
        }
        return duplicate
    }

    func askRemoveColor(_ paletteColor: PaletteColor, save: Bool) -> Bool {
        if let index = originalOrder.firstIndex(where: { $0.id == paletteColor.id }) {
            originalOrder.remove(at: index)
            lastUsedOrder.removeAll { $0.id == paletteColor.id }
            if save {
                saveColors()
            }
            return true
        }
        return false
    }

    func addOrUpdateColor(_ oldColor: PaletteColor?, newValue: Any?, save: Bool) -> PaletteColor? {
        oldColor == nil
            ? addNewColor(newValue, updateLastUsedOrder: true, save: save)
            : updateColor(oldColor, newValue: newValue, save: save)
    }

    func addAllUniqueColors(_ colorInts: [Int]) {
        var originalOrder = getColors(.original)
        var lastUsedOrder = getColors(.lastUsedTime)
        for colorInt in colorInts where !originalOrder.contains(where: { $0.color == colorInt }) {
            let paletteColor = PaletteColor(color: colorInt)
            originalOrder.append(paletteColor)
            lastUsedOrder.append(paletteColor)
        }
        setColors(originalOrder, lastUsedOrder)
    }

    func askRenewLastUsedTime(_ paletteColor: PaletteColor?) {
        if let paletteColor {
            lastUsedOrder.removeAll { $0.id == paletteColor.id }
            lastUsedOrder.insert(paletteColor, at: 0)
            saveColors()
        }
    }

    func getSorting() -> ((PaletteColor, PaletteColor) -> Bool) {
        {
            return $0.getIndex() < $1.getIndex()
        }
    }

    func sortColors() {
        originalOrder.sort(by: getSorting())

        for paletteColor in originalOrder {
            if let index = originalOrder.firstIndex(where: { $0.id == paletteColor.id }) {
                paletteColor.setIndex(index + 1)
            }
        }
    }

    func loadColors() {
        do {
            originalOrder.removeAll()
            lastUsedOrder.removeAll()
            try loadColorsInLastUsedOrder()
            originalOrder.append(contentsOf: lastUsedOrder)
            sortColors()
        } catch {
            debugPrint("Error when trying to read file: \(error.localizedDescription)")
        }
    }

    private func addColorDuplicate(_ list: inout [PaletteColor], original: PaletteColor, duplicate: PaletteColor) {
        if let index = list.firstIndex(where: { $0.id == original.id }) {
            if index >= 0 && index < list.count {
                list.insert(duplicate, at: index + 1)
            } else {
                list.append(duplicate)
            }
        }
    }

    private func addNewColor(_ newValue: Any?, updateLastUsedOrder: Bool, save: Bool) -> PaletteColor? {
        var paletteColor: PaletteColor?
        if let newColor = newValue as? Int {
            paletteColor = PaletteColor(color: newColor)
        } else if let newPaletteColor = newValue as? PaletteColor {
            paletteColor = newPaletteColor
        }
        guard let paletteColor else { return nil }

        originalOrder.append(paletteColor)
        if updateLastUsedOrder {
            lastUsedOrder.insert(paletteColor, at: 0)
        } else {
            lastUsedOrder.append(paletteColor)
        }
        if save {
            saveColors()
        }
        return paletteColor
    }

    internal func updateColor(_ paletteColor: PaletteColor?, newValue: Any?, save: Bool) -> PaletteColor? {
        if let paletteColor, let newColor = newValue as? Int {
            paletteColor.color = newColor
            if save {
                saveColors()
            }
        }
        return paletteColor
    }

    func getPaletteColor(byFileName fileName: String, new: Bool = false) -> PaletteColor? {
        nil
    }

    func loadColorsInLastUsedOrder() throws { }

    func saveColors() { }
}

extension GradientColorsCollection {

    func addToLastUsedOrder(_ gradientColor: PaletteGradientColor) {
        lastUsedOrder.append(gradientColor)
    }
}
