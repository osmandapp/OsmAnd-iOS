//
//  GradientPaletteHelper.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 11.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class GradientPaletteHelper: NSObject {
    static let shared = GradientPaletteHelper()
    
    private var repository: PaletteRepository {
        OsmAndApp.swiftInstance().paletteRepository
    }
    
    private override init() {
        super.init()
    }
    
    func paletteItems(category: GradientPaletteCategory, sortMode: PaletteSortMode) -> [PaletteItemGradient] {
        repository.getPaletteItems(paletteId: category.id, sortMode: sortMode).compactMap { $0 as? PaletteItemGradient }
    }
    
    func paletteItems(gradientScaleType: GradientScaleType?, sortMode: PaletteSortMode) -> [PaletteItemGradient] {
        guard let category = gradientScaleType?.toPaletteCategory() else { return [] }
        return paletteItems(category: category, sortMode: sortMode)
    }
    
    func defaultPaletteItem(category: GradientPaletteCategory) -> PaletteItemGradient? {
        paletteItems(category: category, sortMode: .originalOrder).first { $0.isDefault }
    }
    
    func defaultPaletteItem(gradientScaleType: GradientScaleType?) -> PaletteItemGradient? {
        guard let category = gradientScaleType?.toPaletteCategory() else { return nil }
        return defaultPaletteItem(category: category)
    }
    
    func paletteItem(category: GradientPaletteCategory, name: String?) -> PaletteItemGradient? {
        guard let name, !name.isEmpty else { return nil }
        return repository.findPaletteItem(paletteId: category.id, itemId: name) as? PaletteItemGradient
    }
    
    func paletteItemOrDefault(category: GradientPaletteCategory, name: String?) -> PaletteItemGradient? {
        paletteItem(category: category, name: name) ?? defaultPaletteItem(category: category) ?? paletteItems(category: category, sortMode: .originalOrder).first
    }
    
    func paletteItemOrDefault(gradientScaleType: GradientScaleType?, name: String?) -> PaletteItemGradient? {
        guard let category = gradientScaleType?.toPaletteCategory() else { return nil }
        return paletteItemOrDefault(category: category, name: name)
    }
    
    func index(of paletteItem: PaletteItemGradient?, in items: [PaletteItemGradient]) -> Int {
        guard let paletteItem else { return NSNotFound }
        return items.firstIndex { $0.id == paletteItem.id } ?? NSNotFound
    }
    
    func paletteItem(fileName: String?) -> PaletteItemGradient? {
        guard let paletteData = paletteData(fileName: fileName) else { return nil }
        return paletteItem(category: paletteData.category, name: paletteData.name)
    }
    
    func colorPalette(fileName: String?) -> OsmAndShared.ColorPalette? {
        paletteItem(fileName: fileName)?.getColorPalette()
    }
    
    func isPaletteChangeEvent(_ event: PaletteChangeEvent, fileName: String?) -> Bool {
        guard let paletteData = paletteData(fileName: fileName) else { return false }
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
        guard (category.editable || category == .terrainHillshade), let palette = gradientPalette(id: item.source.paletteId), let newItem = PaletteUtils.shared.createGradientDuplicate(palette: palette, originalItemId: item.id) else { return nil }
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

    func showAddPaletteEditor(from viewController: UIViewController, paletteCategory: GradientPaletteCategory?, sourceView: UIView?) {
        guard let paletteCategory else { return }
        if !OAIAPHelper.isOsmAndProAvailable() {
            guard let navigationController = OARootViewController.instance().navigationController else { return }
            OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.advanced_WIDGETS(), navController: navigationController)
            return
        }

        let rangeTypes = paletteCategory.getSupportedRangeTypes()
        if paletteCategory.isSupportDifferentRangeTypes(), rangeTypes.count > 1 {
            let message = rangeTypes.map {
                let rangeState = GradientEditorRangeState(rangeType: $0)
                return String(format: localizedString("ltr_or_rtl_combine_via_colon"), rangeState.title, rangeState.summary)
            }.joined(separator: "\n")
            let alert = UIAlertController(title: localizedString("add_palette"), message: message, preferredStyle: .actionSheet)
            for rangeType in rangeTypes {
                let rangeState = GradientEditorRangeState(rangeType: rangeType)
                alert.addAction(UIAlertAction(title: rangeState.title, style: .default) { [weak viewController] _ in
                    guard let viewController, let fileType = paletteCategory.getFileType(rangeType: rangeType) else { return }
                    self.openGradientEditor(from: viewController, fileType: fileType)
                })
            }

            if let popoverPresentationController = alert.popoverPresentationController {
                popoverPresentationController.sourceView = sourceView ?? viewController.view
                popoverPresentationController.sourceRect = sourceView?.bounds ?? viewController.view.bounds
            }

            viewController.present(alert, animated: true)
        } else {
            openGradientEditor(from: viewController, fileType: paletteCategory.getFileType())
        }
    }

    func showEditPaletteEditor(from viewController: UIViewController, paletteItem: PaletteItemGradient) {
        if !OAIAPHelper.isOsmAndProAvailable() {
            guard let navigationController = OARootViewController.instance().navigationController else { return }
            OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.advanced_WIDGETS(), navController: navigationController)
            return
        }
        
        openGradientEditor(from: viewController, originalId: paletteItem.id, fileType: paletteItem.properties.fileType)
    }
    
    private func updateExternalDependenciesIfNeeded(category: GradientPaletteCategory) {
        guard category.isTerrainRelated() else { return }
        TerrainMode.reloadTerrainModes()
    }
    
    private func gradientPalette(id: String) -> Palette.GradientCollection? {
        repository.getPalette(id: id) as? Palette.GradientCollection
    }
    
    private func paletteData(fileName: String?) -> (category: GradientPaletteCategory, name: String)? {
        guard let fileName, let fileType = PaletteFileTypeRegistry.shared.fromFileName(fileName: fileName) as? GradientFileType, let paletteName = PaletteUtils.shared.extractPaletteName(fileName: fileName) else { return nil }
        return (fileType.category, paletteName)
    }

    private func openGradientEditor(from viewController: UIViewController, originalId: String? = nil, fileType: GradientFileType) {
        let editor = GradientEditorViewController(originalId: originalId, fileType: fileType)
        let navigationController = UINavigationController(rootViewController: editor)
        navigationController.modalPresentationStyle = .fullScreen
        viewController.present(navigationController, animated: true)
    }
}
