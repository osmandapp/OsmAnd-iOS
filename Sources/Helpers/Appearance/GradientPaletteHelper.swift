//
//  GradientPaletteHelper.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 11.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class GradientPaletteHelper: NSObject {
    static let shared = GradientPaletteHelper()
    
    private var repository: PaletteRepository {
        OsmAndApp.swiftInstance().paletteRepository
    }
    
    private override init() {
        super.init()
    }
    
    func getPaletteItems(category: GradientPaletteCategory, sortMode: PaletteSortMode) -> [PaletteItemGradient] {
        repository.getPaletteItems(paletteId: category.id, sortMode: sortMode).compactMap { $0 as? PaletteItemGradient }
    }
    
    func getPaletteItems(gradientScaleType: GradientScaleType?, sortMode: PaletteSortMode) -> [PaletteItemGradient] {
        guard let category = gradientScaleType?.toPaletteCategory() else { return [] }
        return getPaletteItems(category: category, sortMode: sortMode)
    }
    
    func getDefaultPaletteItem(category: GradientPaletteCategory) -> PaletteItemGradient? {
        getPaletteItems(category: category, sortMode: .originalOrder).first { $0.isDefault }
    }
    
    func getDefaultPaletteItem(gradientScaleType: GradientScaleType?) -> PaletteItemGradient? {
        guard let category = gradientScaleType?.toPaletteCategory() else { return nil }
        return getDefaultPaletteItem(category: category)
    }
    
    func getPaletteItem(category: GradientPaletteCategory, name: String?) -> PaletteItemGradient? {
        guard let name, !name.isEmpty else { return nil }
        return repository.findPaletteItem(paletteId: category.id, itemId: name) as? PaletteItemGradient
    }
    
    func getPaletteItemOrDefault(category: GradientPaletteCategory, name: String?) -> PaletteItemGradient? {
        getPaletteItem(category: category, name: name) ?? getDefaultPaletteItem(category: category) ?? getPaletteItems(category: category, sortMode: .originalOrder).first
    }
    
    func getPaletteItemOrDefault(gradientScaleType: GradientScaleType?, name: String?) -> PaletteItemGradient? {
        guard let category = gradientScaleType?.toPaletteCategory() else { return nil }
        return getPaletteItemOrDefault(category: category, name: name)
    }
    
    func indexOfPaletteItem(_ paletteItem: PaletteItemGradient?, items: [PaletteItemGradient]) -> Int {
        guard let paletteItem else { return NSNotFound }
        return items.firstIndex { $0.id == paletteItem.id } ?? NSNotFound
    }
    
    func getPaletteItem(fileName: String?) -> PaletteItemGradient? {
        guard let paletteData = getPaletteData(fileName: fileName) else { return nil }
        return getPaletteItem(category: paletteData.category, name: paletteData.name)
    }
    
    func getColorPalette(fileName: String?) -> OsmAndShared.ColorPalette? {
        getPaletteItem(fileName: fileName)?.getColorPalette()
    }
    
    func isPaletteChangeEvent(_ event: PaletteChangeEvent, fileName: String?) -> Bool {
        guard let paletteData = getPaletteData(fileName: fileName) else { return false }
        if let removed = event as? PaletteChangeEvent.Removed {
            return removed.paletteId == paletteData.category.id && removed.id == paletteData.name
        }
        
        if let updated = event as? PaletteChangeEvent.Updated, let item = updated.item as? PaletteItemGradient {
            return item.source.paletteId == paletteData.category.id && item.id == paletteData.name
        }
        
        if let added = event as? PaletteChangeEvent.Added, let item = added.item as? PaletteItemGradient {
            return item.source.paletteId == paletteData.category.id && item.id == paletteData.name
        }

        if let replaced = event as? PaletteChangeEvent.Replaced, let item = replaced.newItem as? PaletteItemGradient {
            return item.source.paletteId == paletteData.category.id && (replaced.oldId == paletteData.name || item.id == paletteData.name)
        }
        
        return false
    }
    
    func markPaletteItemAsUsed(_ item: PaletteItemGradient) {
        repository.markPaletteItemAsUsed(paletteId: item.source.paletteId, itemId: item.id)
    }
    
    func duplicatePaletteItem(_ item: PaletteItemGradient) -> PaletteItemGradient? {
        let category = item.properties.fileType.category
        // Android disables duplication for non-editable hillshade palettes; iOS keeps the legacy duplicate action.
        guard (category.editable || category == .terrainHillshade), let palette = getGradientPalette(id: item.source.paletteId), let newItem = PaletteUtils.shared.createGradientDuplicate(palette: palette, originalItemId: item.id) else { return nil }
        repository.insertPaletteItemAfter(paletteId: palette.id, anchorId: item.id, newItem: newItem)
        updateExternalDependenciesIfNeeded(category: category)
        return newItem
    }
    
    @discardableResult func deletePaletteItem(_ item: PaletteItemGradient) -> Bool {
        guard !item.isDefault else { return false }
        repository.removePaletteItem(paletteId: item.source.paletteId, itemId: item.id)
        updateExternalDependenciesIfNeeded(category: item.properties.fileType.category)
        return true
    }
    
    func renamePaletteItem(_ item: PaletteItemGradient, newName: String) -> PaletteItemGradient? {
        let category = item.properties.fileType.category
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard category.editable, item.isEditable, !trimmedName.isEmpty else { return nil }
        let newItem = PaletteUtils.shared.renameGradientPalette(item: item, newName: trimmedName)
        repository.replacePaletteItem(paletteId: item.source.paletteId, oldItemId: item.id, newItem: newItem)
        updateExternalDependenciesIfNeeded(category: category)
        return newItem
    }
    
    private func updateExternalDependenciesIfNeeded(category: GradientPaletteCategory) {
        if category.isTerrainRelated() {
            TerrainMode.reloadTerrainModes()
        }
    }
    
    private func getGradientPalette(id: String) -> Palette.GradientCollection? {
        repository.getPalette(id: id) as? Palette.GradientCollection
    }
    
    private func getPaletteData(fileName: String?) -> (category: GradientPaletteCategory, name: String)? {
        guard let fileName, let fileType = PaletteFileTypeRegistry.shared.fromFileName(fileName: fileName) as? GradientFileType, let paletteName = PaletteUtils.shared.extractPaletteName(fileName: fileName) else { return nil }
        return (fileType.category, paletteName)
    }
}
