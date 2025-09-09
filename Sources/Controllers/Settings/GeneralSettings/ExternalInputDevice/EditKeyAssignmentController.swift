//
//  EditKeyAssignmentController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class EditKeyAssignmentController: OABaseSettingsViewController {
    private static let actionKey = "actionKey"
    private static let assignedKeysRowKey = "assignedKeysRowKey"
    private static let assignedKeysKey = "assignedKeysKey"
    
    var keyAssignment: KeyAssignment?
    var deviceId: String?
    var isAdd = false
    
    private var isEditMode: Bool = false {
        didSet {
            tableView.setEditing(isEditMode, animated: true)
            updateUIAnimated(nil)
        }
    }
    
    override func registerCells() {
        addCell(KeyAssignmentTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String? {
        if isEditMode {
            return localizedString("shared_string_edit")
        } else if isAdd {
            return localizedString("new_key_assignment")
        } else {
            return keyAssignment?.getName()
        }
    }
    
    override func generateData() {
        tableData.clearAllData()
        guard let keyAssignment else { return }
        let actionSection = tableData.createNewSection()
        actionSection.headerText = localizedString("shared_string_action")
        let actionRow = actionSection.createNewRow()
        actionRow.cellType = KeyAssignmentTableViewCell.reuseIdentifier
        actionRow.key = Self.actionKey
        actionRow.title = keyAssignment.getName()
        actionRow.iconName = keyAssignment.getIcon()
        actionRow.iconTintColor = appMode.getProfileColor()
        
        let assignedKeysSection = tableData.createNewSection()
        assignedKeysSection.headerText = localizedString("assigned_keys")
        let assignedKeysRow = assignedKeysSection.createNewRow()
        assignedKeysRow.cellType = KeyAssignmentTableViewCell.reuseIdentifier
        assignedKeysRow.key = Self.assignedKeysRowKey
        assignedKeysRow.setObj(keyAssignment.getKeyCodes(), forKey: Self.assignedKeysKey)
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == KeyAssignmentTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: KeyAssignmentTableViewCell.reuseIdentifier, for: indexPath) as! KeyAssignmentTableViewCell
            cell.selectionStyle = .none
            cell.descriptionVisibility(false)
            if item.key == Self.actionKey {
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
                cell.leftIconView.tintColor = item.iconTintColor
                cell.titleLabel.text = item.title
                cell.titleLabel.accessibilityLabel = item.title
            } else if item.key == Self.assignedKeysRowKey, let keyCodes = item.obj(forKey: Self.assignedKeysKey) as? [UIKeyboardHIDUsage] {
                cell.titleVisibility(false)
                cell.leftIconVisibility(false)
                cell.configure(keyCodes: keyCodes, horizontalSpace: 16, fontSize: 17, additionalVerticalSpace: 11, keySpacing: 10, isAlignedToLeading: true)
            }
            return cell
        }
        return nil
    }
    
    override func onLeftNavbarButtonPressed() {
        if isEditMode {
            switchEditMode(to: false)
        } else {
            super.onLeftNavbarButtonPressed()
        }
    }
    
    override func onRightNavbarButtonPressed() {
        if isEditMode {
            switchEditMode(to: false)
        } else if isAdd {
            dismiss()
        }
    }
    
    override func getLeftNavbarButtonTitle() -> String? {
        isAdd || isEditMode ? localizedString("shared_string_cancel") : nil
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        var menuElements: [UIMenuElement]?
        if !isEditMode && !isAdd {
            let editAction: UIAction = UIAction(title: localizedString("shared_string_edit"),
                                                image: UIImage(named: "ic_custom_key_edit")) { [weak self] _ in
                guard let self else { return }
                self.switchEditMode(to: true)
            }
            let renameAction: UIAction = UIAction(title: localizedString("shared_string_rename"),
                                                  image: UIImage(named: "ic_custom_edit")) { [weak self] _ in
                guard let self else { return }
                self.showRenameAlert()
            }
            let removeAction: UIAction = UIAction(title: localizedString("shared_string_remove"),
                                                  image: UIImage(named: "ic_custom_trash_outlined")?.withTintColor(.iconColorDisruptive, renderingMode: .alwaysOriginal)) { [weak self] _ in
                guard let self else { return }
                self.showRemoveAlert()
            }
            let removeMenuAction: UIMenu = UIMenu(options: .displayInline, children: [removeAction])
            menuElements = [editAction, renameAction, removeMenuAction]
        }
        let menu: UIMenu? = isEditMode || isAdd ? nil : UIMenu(children: menuElements ?? [])
        let button: UIBarButtonItem?
        
        if isAdd {
            button = createRightNavbarButton(localizedString("shared_string_save"),
                                             iconName: nil,
                                             action: #selector(onRightNavbarButtonPressed),
                                             menu: menu)
        } else {
            button = createRightNavbarButton(isEditMode ? localizedString("shared_string_done") : nil,
                                             iconName: isEditMode ? nil : "ic_navbar_overflow_menu_stroke",
                                             action: #selector(onRightNavbarButtonPressed),
                                             menu: menu)
        }
        
        if !isEditMode && !isAdd {
            button?.accessibilityLabel = localizedString("shared_string_options")
        }
        return button.flatMap { [$0] } ?? []
    }
    
    private func showRenameAlert() {
        let alert = UIAlertController(title: localizedString("shared_string_rename"),
                                      message: nil,
                                      preferredStyle: .alert)

        alert.addTextField { [weak self] textField in
            guard let self else { return }
            textField.placeholder = self.keyAssignment?.getName()
        }

        let saveAction = UIAlertAction(title: localizedString("shared_string_save"), style: .default) { [weak self, weak alert] _ in
            guard let self, let deviceId, let device = InputDevicesHelper.shared.getDeviceById(appMode, deviceId) else { return }
            
            let name = (alert?.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let hasKeyAssignmentName = device.getAssignments().contains { $0.getName()?.trimmingCharacters(in: .whitespacesAndNewlines) == name }
            
            guard !name.isEmpty, !hasKeyAssignmentName else { return }
            self.keyAssignment?.setCustomName(name)
            self.title = getTitle()
            self.renameKeyAssignment(with: name)
            updateAppearance()
        }

        let cancelAction = UIAlertAction(title: localizedString("shared_string_cancel"), style: .default, handler: nil)

        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        alert.preferredAction = saveAction

        present(alert, animated: true, completion: nil)
    }
    
    private func showRemoveAlert() {
        let alert = UIAlertController(title: localizedString("remove_key_assignment"), message: localizedString("remove_key_assignment_summary"), preferredStyle: .alert)

        let removeAction = UIAlertAction(title: localizedString("shared_string_remove"), style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.removeKeyAssignment()
        }

        let cancelAction = UIAlertAction(title: localizedString("shared_string_cancel"), style: .default, handler: nil)

        alert.addAction(cancelAction)
        alert.addAction(removeAction)

        present(alert, animated: true, completion: nil)
    }
    
    private func switchEditMode(to on: Bool) {
        isEditMode = on
    }
    
    private func renameKeyAssignment(with name: String) {
        guard let deviceId, let keyAssignmentId = keyAssignment?.getId() else { return }
        InputDevicesHelper.shared.renameAssignment(with: appMode, deviceId: deviceId, assignmentId: keyAssignmentId, newName: name)
        delegate.onSettingsChanged()
    }
    
    private func removeKeyAssignment() {
        guard let deviceId, let keyAssignmentId = keyAssignment?.getId() else { return }
        InputDevicesHelper.shared.removeKeyAssignmentCompletely(with: appMode, deviceId: deviceId, assignmentId: keyAssignmentId)
        delegate.onSettingsChanged()
        dismiss()
    }
}
