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

    private(set) var originalOrder: [PaletteColor] = []
    fileprivate(set) var lastUsedOrder: [PaletteColor] = []

    func findPaletteColor(_ colorInt: Int) -> PaletteColor? {
        findPaletteColor(colorInt, registerIfNotFound: false)
    }

    func findPaletteColor(_ colorInt: Int, registerIfNotFound: Bool) -> PaletteColor? {
        for paletteColor in originalOrder where paletteColor.color == colorInt {
            return paletteColor
        }
        return registerIfNotFound ? addNewColor(colorInt, updateLastUsedOrder: false) : nil
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

    func duplicateColor(_ paletteColor: PaletteColor) -> PaletteColor {
        let duplicate = paletteColor.duplicate()
        addColorDuplicate(&originalOrder, original: paletteColor, duplicate: duplicate)
        addColorDuplicate(&lastUsedOrder, original: paletteColor, duplicate: duplicate)
        saveColors()
        return duplicate
    }

    func askRemoveColor(_ paletteColor: PaletteColor) -> Bool {
        if let index = originalOrder.firstIndex(where: { $0.id == paletteColor.id }) {
            originalOrder.remove(at: index)
            lastUsedOrder.removeAll { $0.id == paletteColor.id }
            saveColors()
            return true
        }
        return false
    }

    func addOrUpdateColor(_ oldColor: PaletteColor?, newColor: Int) -> PaletteColor? {
        oldColor == nil ? addNewColor(newColor, updateLastUsedOrder: true) : updateColor(oldColor, newColor: newColor)
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

    func loadColors() {
        do {
            originalOrder.removeAll()
            lastUsedOrder.removeAll()
            try loadColorsInLastUsedOrder()
            originalOrder.append(contentsOf: lastUsedOrder)
            originalOrder.sort { $0.getIndex() < $1.getIndex() }
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

    private func addNewColor(_ newColor: Int, updateLastUsedOrder: Bool) -> PaletteColor {
        let paletteColor = PaletteColor(color: newColor)
        originalOrder.append(paletteColor)
        if updateLastUsedOrder {
            lastUsedOrder.insert(paletteColor, at: 0)
        } else {
            lastUsedOrder.append(paletteColor)
        }
        saveColors()
        return paletteColor
    }

    private func updateColor(_ paletteColor: PaletteColor?, newColor: Int) -> PaletteColor? {
        if let paletteColor {
            paletteColor.color = newColor
            saveColors()
        }
        return paletteColor
    }

    func loadColorsInLastUsedOrder() throws {
        // override
    }

    func saveColors() {
        // override
    }
}

extension GradientColorsCollection {

    func addToLastUsedOrder(_ gradientColor: PaletteGradientColor) {
        lastUsedOrder.append(gradientColor)
    }
}
