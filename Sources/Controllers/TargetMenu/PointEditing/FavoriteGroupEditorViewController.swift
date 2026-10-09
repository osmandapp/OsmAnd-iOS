//
//  FavoriteGroupEditorViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.10.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class FavoriteGroupEditorViewController: OAGroupEditorViewController {
    var parentGroupName: String?
    
    private var favoriteGroup: OAFavoriteGroup?
    private var progressHUD: MBProgressHUD?
    private var applyToExistingIndexPath: IndexPath?
    private var lastAppliedColor: UIColor?
    private var lastAppliedIconName: String?
    private var lastAppliedBackgroundIconName: String?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let progressHUD, let window = navigationController?.view.window ?? view.window {
            progressHUD.frame = window.bounds
            window.addSubview(progressHUD)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progressHUD?.removeFromSuperview()
    }
    
    override func postInit() {
        super.postInit()
        if isNewItem {
            let group = OAFavoriteGroup()
            group.name = editName
            group.color = editColor
            group.isVisible = true
            group.iconName = editIconName
            group.backgroundType = editBackgroundIconName
            favoriteGroup = group
        } else {
            favoriteGroup = OAFavoritesHelperBridge.shared().favoriteGroup(withName: editName)
        }
    }
    
    override func shouldBlurAppearanceNavBar() -> Bool {
        false
    }
    
    override func existingGroup(for name: String?) -> OAFavoriteGroup? {
        let groupName = targetGroupName(for: name)
        let group = OAFavoritesHelperBridge.shared().group(byTrimmedName: groupName)
        if group != nil || !isNewItem {
            return group
        }
        
        let languageCode = OAUtilities.currentLang() ?? ""
        let locale = languageCode.isEmpty ? Locale.current : Locale(identifier: languageCode)
        let lowercaseGroupName = groupName.lowercased(with: locale)
        for favoriteGroup in OAFavoritesHelperBridge.shared().favoriteGroups() {
            if favoriteGroup.name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(with: locale) == lowercaseGroupName || OAFavoriteGroup.getDisplayName(favoriteGroup.name) == groupName {
                return favoriteGroup
            }
        }

        return nil
    }
    
    override func allowsValidationForGroupName() -> Bool {
        !isNewItem
    }
    
    override func registerCells() {
        super.registerCells()
        addCell(OASearchMoreCell.reuseIdentifier)
    }
    
    override func generateActionSection() {
        guard !isNewItem else { return }
        let section = tableData.createNewSection()
        let row = section.createNewRow()
        row.cellType = OASearchMoreCell.reuseIdentifier
        row.title = String(format: localizedString("ltr_or_rtl_combine_via_space"), localizedString("apply_to_existing"), "(\(favoriteGroup?.points?.count ?? 0))")
        applyToExistingIndexPath = IndexPath(row: Int(section.rowCount()) - 1, section: Int(tableData.sectionCount()) - 1)
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell {
        let row = tableData.item(for: indexPath)
        guard row.cellType == OASearchMoreCell.reuseIdentifier, let cell = tableView.dequeueReusableCell(withIdentifier: OASearchMoreCell.reuseIdentifier, for: indexPath) as? OASearchMoreCell else { return super.getRow(indexPath) }
        cell.textView.text = row.title
        cell.textView.font = .preferredFont(forTextStyle: .body)
        cell.textView.numberOfLines = 0
        updateApplyToExistingCell(cell)
        return cell
    }
    
    override func changeSaveButtonAvailabilityWithGroup() {
        super.changeSaveButtonAvailabilityWithGroup()
        if let applyToExistingIndexPath {
            updateApplyToExistingCell(tableView.cellForRow(at: applyToExistingIndexPath) as? OASearchMoreCell)
        }
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let row = tableData.item(for: indexPath)
        guard row.cellType == OASearchMoreCell.reuseIdentifier else {
            super.onRowSelected(indexPath)
            return
        }

        if isExistingPointsAppearanceChanged() && (favoriteGroup?.points?.count ?? 0) > 0 {
            editPointsGroup(true, updateGroupValues: false)
        }
    }
    
    override func onRightNavbarButtonPressed() {
        if isNewItem {
            addPointsGroup()
        } else {
            let alert = UIAlertController(title: localizedString("shared_string_save"), message: localizedString("save_favorite_default_appearance"), preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: localizedString("apply_only_to_new_points"), style: .default) { _ in
                self.editPointsGroup(false, updateGroupValues: true)
            })

            alert.addAction(UIAlertAction(title: localizedString("apply_to_all_points"), style: .default) { _ in
                self.editPointsGroup(true, updateGroupValues: true)
            })

            alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
            
            let popover = alert.popoverPresentationController
            popover?.barButtonItem = navigationItem.rightBarButtonItem
            popover?.permittedArrowDirections = .any
            present(alert, animated: true)
        }
    }
    
    override func onLeftNavbarButtonPressed() {
        if isNewItem || !isExistingPointsAppearanceChanged() {
            super.onLeftNavbarButtonPressed()
        } else {
            let alert = UIAlertController(title: localizedString("exit_without_saving"), message: localizedString("unsaved_changes_will_be_lost"), preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
            alert.addAction(UIAlertAction(title: localizedString("shared_string_exit"), style: .destructive) { _ in
                super.onLeftNavbarButtonPressed()
            })

            alert.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
            present(alert, animated: true)
        }
    }
    
    private func updateApplyToExistingCell(_ cell: OASearchMoreCell?) {
        guard let cell else { return }
        let enabled = isExistingPointsAppearanceChanged() && (favoriteGroup?.points?.count ?? 0) > 0
        cell.selectionStyle = enabled ? .default : .none
        cell.textView.textColor = enabled ? .textColorActive : .textColorSecondary
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = cell.textView.text
        cell.textView.isAccessibilityElement = false
        cell.accessibilityTraits = enabled ? .button : [.button, .notEnabled]
    }
    
    private func isExistingPointsAppearanceChanged() -> Bool {
        guard let lastAppliedColor else { return isAppearanceChanged() }
        return editColor != lastAppliedColor || isIconNameChanged(lastAppliedIconName) || editBackgroundIconName != lastAppliedBackgroundIconName
    }
    
    private func targetGroupName(for name: String?) -> String {
        let trimmedName = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let parentGroupName = parentGroupName ?? ""
        if !parentGroupName.isEmpty && !trimmedName.isEmpty {
            return "\(parentGroupName)/\(trimmedName)"
        } else if !trimmedName.isEmpty {
            return trimmedName
        } else {
            return parentGroupName
        }
    }
    
    private func addPointsGroup() {
        dismiss()
        delegate?.addNewItem(withName: editName, iconName: editIconName, color: editColor, backgroundIconName: editBackgroundIconName)
    }
    
    private func editPointsGroup(_ updatePoints: Bool, updateGroupValues: Bool) {
        view.endEditing(true)
        let containerView = view.window ?? view
        progressHUD = MBProgressHUD.showAdded(to: containerView, animated: false)
        progressHUD?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        progressHUD?.accessibilityViewIsModal = true
        if isIconNameChanged(favoriteGroup?.iconName) || (updatePoints && lastAppliedIconName != nil && isIconNameChanged(lastAppliedIconName)) {
            OAFavoritesHelperBridge.shared().update(favoriteGroup, iconName: editIconName, updatePoints: updatePoints, updateGroupIcon: updateGroupValues, saveImmediately: false) {
                self.finishSavingGroup(updatePoints, updateGroupValues: updateGroupValues)
            }
        } else {
            finishSavingGroup(updatePoints, updateGroupValues: updateGroupValues)
        }
    }
    
    private func finishSavingGroup(_ updatePoints: Bool, updateGroupValues: Bool) {
        finishEditingPointsGroup(updatePoints, updateGroupValues: updateGroupValues)
        if updatePoints {
            lastAppliedColor = editColor
            lastAppliedIconName = editIconName
            lastAppliedBackgroundIconName = editBackgroundIconName
            changeSaveButtonAvailabilityWithGroup()
        }
        
        progressHUD?.hide(false)
        progressHUD = nil
        delegate?.onEditorUpdated?()
        if navigationController?.topViewController === self {
            if updateGroupValues {
                dismiss()
            } else {
                OAUtilities.showToast(localizedString("settings_applied"), details: nil, duration: 4, verticalOffset: 50, in: view)
            }
        }
    }
    
    private func finishEditingPointsGroup(_ updatePoints: Bool, updateGroupValues: Bool) {
        getPoiIconCollectionHandler().addIconToLastUsed(editIconName)
        if editColor != favoriteGroup?.color || (updatePoints && lastAppliedColor != nil && editColor != lastAppliedColor) {
            OAFavoritesHelperBridge.shared().update(favoriteGroup, color: editColor, updatePoints: updatePoints, updateGroupColor: updateGroupValues, saveImmediately: false)
        }

        if editBackgroundIconName != favoriteGroup?.backgroundType || (updatePoints && lastAppliedBackgroundIconName != nil && editBackgroundIconName != lastAppliedBackgroundIconName) {
            OAFavoritesHelperBridge.shared().update(favoriteGroup, backgroundIconName: editBackgroundIconName, updatePoints: updatePoints, updateGroupShape: updateGroupValues, saveImmediately: false)
        }

        OAFavoritesHelperBridge.shared().update(favoriteGroup, newName: editName, saveImmediately: false)
        OAFavoritesHelperBridge.shared().notifyFavoritesStorageChanged()
        OAFavoritesHelperBridge.shared().saveCurrentPointsIntoFile()
    }
}
