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

    func refreshImportedPalette(fileName: String?) {
        guard let category = paletteData(fileName: fileName)?.category else { return }
        repository.invalidatePalette(id: category.id)
        updateExternalDependenciesIfNeeded(category: category)
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

    func updatedTerrainPaletteFileName(_ event: PaletteChangeEvent) -> String? {
        guard let updated = event as? PaletteChangeEvent.Updated, let item = updated.item as? PaletteItemGradient, item.properties.fileType.category.isTerrainRelated() else { return nil }
        return item.source.fileName
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
        guard category.editable, item.isEditable, !trimmedName.isEmpty, let palette = gradientPalette(id: item.source.paletteId) else { return nil }
        let newItem = PaletteUtils.shared.renameGradientPalette(item: item, newName: trimmedName)
        guard !containsPaletteItem(withId: newItem.id, in: palette) else { return nil }
        repository.replacePaletteItem(paletteId: item.source.paletteId, oldItemId: item.id, newItem: newItem)
        updateRenamedPaletteDependencies(from: item, to: newItem)
        updateExternalDependenciesIfNeeded(category: category)
        return newItem
    }

    func suggestedPaletteName(for draft: GradientDraft) -> String? {
        guard let palette = gradientPalette(id: draft.fileType.category.id) else { return nil }
        return PaletteUtils.shared.createGradientColor(palette: palette, fileType: draft.fileType, points: draft.points, noDataColor: draft.noDataColor.map { KotlinInt(integerLiteral: Int($0)) }).displayName
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
                String(format: localizedString("ltr_or_rtl_combine_via_colon"), $0.getTitle(), $0.getSummary())
            }.joined(separator: "\n")
            let alert = UIAlertController(title: localizedString("add_palette"), message: message, preferredStyle: .actionSheet)
            for rangeType in rangeTypes {
                alert.addAction(UIAlertAction(title: rangeType.getTitle(), style: .default) { [weak viewController] _ in
                    guard let viewController, let fileType = paletteCategory.getFileType(rangeType: rangeType) else { return }
                    self.openGradientEditor(from: viewController, fileType: fileType)
                })
            }
    
            alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
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
    
    private func applyGradientEdits(_ draft: GradientDraft, newName: String?) -> PaletteItemGradient? {
        guard let palette = gradientPalette(id: draft.fileType.category.id) else { return nil }
        let noDataColor = draft.noDataColor.map { KotlinInt(integerLiteral: Int($0)) }
        let resultItem: PaletteItemGradient
        if let originalId = draft.originalId, let item = paletteItem(category: draft.fileType.category, name: originalId) {
            resultItem = item.doCopy(id: item.id, displayName: item.displayName, source: item.source, isDefault: item.isDefault, isEditable: item.isEditable, historyIndex: item.historyIndex, lastUsedTime: item.lastUsedTime, points: draft.points, noDataColor: noDataColor, properties: item.properties)
            repository.updatePaletteItem(item: resultItem)
        } else {
            let newItem = PaletteUtils.shared.createGradientColor(palette: palette, fileType: draft.fileType, points: draft.points, noDataColor: noDataColor)
            resultItem = newName.map { PaletteUtils.shared.renameGradientPalette(item: newItem, newName: $0) } ?? newItem
            guard !containsPaletteItem(withId: resultItem.id, in: palette) else { return nil }
            repository.addPaletteItem(paletteId: palette.id, newItem: resultItem)
        }

        updateExternalDependenciesIfNeeded(category: draft.fileType.category)
        return resultItem
    }

    private func updateRenamedPaletteDependencies(from oldItem: PaletteItemGradient, to newItem: PaletteItemGradient) {
        let categoryId = oldItem.properties.fileType.category.id
        for dataItem in GpxDbHelper.shared.getItems() {
            guard dataItem.coloringType == categoryId, dataItem.gradientPaletteName == oldItem.id else { continue }
            dataItem.gradientPaletteName = newItem.id
            GpxDbHelper.shared.updateDataItem(item: dataItem)
        }

        let settings = OAAppSettings.sharedManager()
        if settings.currentTrackColoringType.get().name == categoryId, settings.currentTrackGradientPalette.get() == oldItem.id {
            settings.currentTrackGradientPalette.set(newItem.id)
        }

        for mode in OAApplicationMode.allPossibleValues() {
            guard settings.routeColoringType.get(mode).name == categoryId, settings.routeGradientPalette.get(mode) == oldItem.id else { continue }
            settings.routeGradientPalette.set(newItem.id, mode: mode)
        }
    }

    private func containsPaletteItem(withId id: String, in palette: Palette.GradientCollection) -> Bool {
        palette.items.contains { $0.id.lowercased() == id.lowercased() }
    }

    private func gradientPalette(id: String) -> Palette.GradientCollection? {
        repository.getPalette(id: id) as? Palette.GradientCollection
    }
    
    private func paletteData(fileName: String?) -> (category: GradientPaletteCategory, name: String)? {
        guard let fileName, let fileType = PaletteFileTypeRegistry.shared.fromFileName(fileName: fileName) as? GradientFileType, let paletteName = PaletteUtils.shared.extractPaletteName(fileName: fileName) else { return nil }
        return (fileType.category, paletteName)
    }

    private func openGradientEditor(from viewController: UIViewController, originalId: String? = nil, fileType: GradientFileType) {
        let editor = GradientEditorViewController(originalId: originalId, fileType: fileType) { [weak self, weak viewController] draft, newName in
            guard let self, let paletteItem = self.applyGradientEdits(draft, newName: newName) else { return false }
            self.applyPaletteEditorResult(paletteItem, replacing: draft.originalId, from: viewController)
            return true
        }

        let navigationController = UINavigationController(rootViewController: editor)
        navigationController.modalPresentationStyle = .fullScreen
        viewController.present(navigationController, animated: true)
    }

    private func applyPaletteEditorResult(_ paletteItem: PaletteItemGradient, replacing originalId: String?, from viewController: UIViewController?) {
        if let itemsViewController = viewController as? ItemsCollectionViewController {
            itemsViewController.applyPaletteEditorResult(paletteItem, replacing: originalId)
        } else if let delegate = viewController as? ColorCollectionViewControllerDelegate {
            delegate.selectPaletteItem?(paletteItem)
        }
    }
}
