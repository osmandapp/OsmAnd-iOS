//
//  EditKeyAssignmentController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class EditKeyAssignmentController: OABaseSettingsViewController {
    private static let actionKey = "actionKey"
    private static let addActionKey = "addActionKey"
    private static let addKeyKey = "addKeyKey"
    private static let assignedKeysRowKey = "assignedKeysRowKey"
    private static let assignedKeysKey = "assignedKeysKey"
    
    var keyAssignment: KeyAssignment?
    var deviceId: String?
    var action: OAQuickAction?
    var keyCodes: [UIKeyboardHIDUsage] = []
    var isAdd = false
    
    private var rightNavButton: UIBarButtonItem?
    private var actionToRemove: OAQuickAction?
    private var originalKeyCodes: [UIKeyboardHIDUsage] = []
    private let maxKeyCount = 5
    
    private var isEditMode: Bool = false {
        didSet {
            tableView.setEditing(isEditMode, animated: true)
            updateUIAnimated(nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsSelectionDuringEditing = true
        originalKeyCodes = keyCodes
        guard isAdd else { return }
        tableView.setEditing(true, animated: true)
        updateUIAnimated(nil)
    }
    
    override func registerCells() {
        addCell(KeyAssignmentTableViewCell.reuseIdentifier)
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String? {
        if isEditMode {
            return localizedString("shared_string_edit")
        } else if isAdd {
            return localizedString("new_key_assignment")
        } else {
            return keyAssignment?.name()
        }
    }
    
    override func generateData() {
        tableData.clearAllData()
        let actionSection = tableData.createNewSection()
        actionSection.headerText = localizedString("shared_string_action")
        if action != nil && actionToRemove != action {
            let actionRow = actionSection.createNewRow()
            actionRow.cellType = OASimpleTableViewCell.reuseIdentifier
            actionRow.key = Self.actionKey
            actionRow.title = action?.getName()
            actionRow.iconName = action?.getIconResName()
            actionRow.iconTintColor = appMode.getProfileColor()
        } else if isAdd || isEditMode {
            let addActionRow = actionSection.createNewRow()
            addActionRow.cellType = OASimpleTableViewCell.reuseIdentifier
            addActionRow.key = Self.addActionKey
            addActionRow.title = localizedString("key_assignment_add_action")
            addActionRow.iconName = "ic_custom_key_plus"
        }
        
        let assignedKeysSection = tableData.createNewSection()
        assignedKeysSection.headerText = localizedString("assigned_keys")
        if isAdd || isEditMode {
            for keyCode in keyCodes {
                let editAssignedKeysRow = assignedKeysSection.createNewRow()
                editAssignedKeysRow.cellType = KeyAssignmentTableViewCell.reuseIdentifier
                editAssignedKeysRow.title = String(format: localizedString("key_name_pattern"), KeySymbolMapper.keySymbol(for: keyCode))
            }
            
            if keyCodes.count < maxKeyCount {
                let addKeyRow = assignedKeysSection.createNewRow()
                addKeyRow.cellType = OASimpleTableViewCell.reuseIdentifier
                addKeyRow.key = Self.addKeyKey
                addKeyRow.title = localizedString("key_assignment_add_key")
                addKeyRow.iconName = "ic_custom_key_plus"
            }
        } else if let keyAssignment {
            let assignedKeysRow = assignedKeysSection.createNewRow()
            assignedKeysRow.cellType = KeyAssignmentTableViewCell.reuseIdentifier
            assignedKeysRow.key = Self.assignedKeysRowKey
            assignedKeysRow.setObj(keyAssignment.storedKeyCodes(), forKey: Self.assignedKeysKey)
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == KeyAssignmentTableViewCell.reuseIdentifier,
           let cell = tableView.dequeueReusableCell(withIdentifier: KeyAssignmentTableViewCell.reuseIdentifier, for: indexPath) as? KeyAssignmentTableViewCell {
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            if let keyCodes = item.obj(forKey: Self.assignedKeysKey) as? [UIKeyboardHIDUsage], !isAdd && !isEditMode {
                cell.titleVisibility(false)
                cell.configure(keyCodes: keyCodes, horizontalSpace: 16, fontSize: 17, cellHeight: 68, keySpacing: 10, isAlignedToLeading: true)
            } else {
                cell.titleVisibility(true)
                cell.configure(keyCodes: [keyCodes[indexPath.row]])
                cell.setTitle(item.title)
            }
            return cell
        } else if item.cellType == OASimpleTableViewCell.reuseIdentifier,
                  let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as? OASimpleTableViewCell {
            cell.descriptionVisibility(false)
            if item.key == Self.actionKey {
                cell.selectionStyle = .none
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
                cell.leftIconView.tintColor = item.iconTintColor
            } else {
                cell.selectionStyle = .default
                cell.leftIconView.image = item.iconName.flatMap(UIImage.init(named:))?.withRenderingMode(.alwaysOriginal)
                cell.setLeftIconSize(24)
            }
            cell.titleLabel.text = item.title
            cell.titleLabel.accessibilityLabel = item.title
            return cell
        }
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        guard let tableData else { return }
        let item = tableData.item(for: indexPath)
        if item.key == Self.addActionKey {
            let addActionController = OAAddQuickActionViewController(keyAssignmentFlow: true)
            addActionController.editKeyAssignmentdelegate = self
            show(addActionController)
        } else if item.key == Self.addKeyKey, let addKeyViewController = AddKeyViewController(appMode: appMode) {
            addKeyViewController.deviceId = deviceId
            addKeyViewController.action = action
            addKeyViewController.keyCodes = keyCodes
            addKeyViewController.delegate = self
            addKeyViewController.addKeyDelegate = self
            show(addKeyViewController)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let tableData else { return false }
        let item = tableData.item(for: indexPath)
        return (isEditMode || isAdd) && item.key != Self.addActionKey && item.key != Self.addKeyKey
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, let tableData else { return }
        let item = tableData.item(for: indexPath)
        if item.key == Self.actionKey {
            if actionToRemove == nil {
                actionToRemove = action
            }
            action = nil
        } else if !keyCodes.isEmpty {
            keyCodes.remove(at: indexPath.row)
        }
        changeRightNavButtonAvailability()
        reloadDataWith(animated: true, completion: nil)
    }
    
    override func onLeftNavbarButtonPressed() {
        if isEditMode {
            if let actionToRemove {
                action = actionToRemove
            }
            actionToRemove = nil
            keyCodes = originalKeyCodes
            switchEditMode(to: false)
        } else {
            super.onLeftNavbarButtonPressed()
        }
    }
    
    override func onRightNavbarButtonPressed() {
        if let deviceId {
            if isEditMode, let keyAssignmentId = keyAssignment?.storedId(), let action {
                InputDevicesHelper.shared.updateAssignment(with: appMode, deviceId: deviceId, assignmentId: keyAssignmentId, action: action, keyCodes: keyCodes)
                actionToRemove = nil
                originalKeyCodes = keyCodes
                switchEditMode(to: false)
            } else if isAdd {
                let keyAssignment = KeyAssignment(action: action, keyCodes: keyCodes)
                InputDevicesHelper.shared.addAssignment(with: appMode, deviceId: deviceId, assignment: keyAssignment)
                dismiss()
            }
            delegate.onSettingsChanged()
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
        
        if isAdd {
            rightNavButton = createRightNavbarButton(localizedString("shared_string_save"),
                                                     iconName: nil,
                                                     action: #selector(onRightNavbarButtonPressed),
                                                     menu: menu)
        } else {
            rightNavButton = createRightNavbarButton(isEditMode ? localizedString("shared_string_apply") : nil,
                                                     iconName: isEditMode ? nil : "ic_navbar_overflow_menu_stroke",
                                                     action: #selector(onRightNavbarButtonPressed),
                                                     menu: menu)
        }
        
        if !isEditMode && !isAdd {
            rightNavButton?.accessibilityLabel = localizedString("shared_string_options")
        } else {
            rightNavButton?.accessibilityLabel = localizedString(isAdd ? "shared_string_save" : "shared_string_apply")
            changeRightNavButtonAvailability()
        }
        return rightNavButton.flatMap { [$0] } ?? []
    }
    
    override func onSettingsChanged() {
        super.onSettingsChanged()
        reloadDataWith(animated: true, completion: nil)
    }
    
    private func showRenameAlert() {
        let alert = UIAlertController(title: localizedString("shared_string_rename"),
                                      message: nil,
                                      preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = self.keyAssignment?.name()
        }

        let saveAction = UIAlertAction(title: localizedString("shared_string_save"), style: .default) { [weak alert] _ in
            guard let deviceId = self.deviceId, let device = InputDevicesHelper.shared.deviceById(self.appMode, deviceId) else { return }
            
            let name = (alert?.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let hasKeyAssignmentName = device.filledAssignments().contains { $0.name()?.trimmingCharacters(in: .whitespacesAndNewlines) == name }
            
            if !name.isEmpty, !hasKeyAssignmentName {
                self.renameKeyAssignment(with: name)
            }
        }

        let cancelAction = UIAlertAction(title: localizedString("shared_string_cancel"), style: .default, handler: nil)

        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        alert.preferredAction = saveAction

        present(alert, animated: true, completion: nil)
    }
    
    private func showRemoveAlert() {
        let alert = UIAlertController(title: localizedString("remove_key_assignment"), message: localizedString("remove_key_assignment_summary"), preferredStyle: .alert)

        let removeAction = UIAlertAction(title: localizedString("shared_string_remove"), style: .destructive) { _ in
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
        guard let deviceId, let keyAssignmentId = keyAssignment?.storedId() else { return }
        keyAssignment?.setCustomName(name)
        InputDevicesHelper.shared.renameAssignment(with: appMode, deviceId: deviceId, assignmentId: keyAssignmentId, newName: name)
        delegate.onSettingsChanged()
        refreshUI()
    }
    
    private func removeKeyAssignment() {
        guard let deviceId, let keyAssignmentId = keyAssignment?.storedId() else { return }
        InputDevicesHelper.shared.removeKeyAssignmentCompletely(with: appMode, deviceId: deviceId, assignmentId: keyAssignmentId)
        delegate.onSettingsChanged()
        dismiss()
    }
    
    private func changeRightNavButtonAvailability() {
        changeButtonAvailability(rightNavButton, isEnabled: !keyCodes.isEmpty && action != nil)
    }
}

extension EditKeyAssignmentController: OAEditKeyAssignmentDelegate {
    func setKeyAssignemntAction(_ action: OAQuickAction) {
        self.action = action
        reloadDataWith(animated: true, completion: nil)
        changeRightNavButtonAvailability()
    }
}

extension EditKeyAssignmentController: AddKeyDelegate {
    func setKey(_ keyCode: UIKeyboardHIDUsage) {
        keyCodes.append(keyCode)
        reloadDataWith(animated: true, completion: nil)
        changeRightNavButtonAvailability()
    }
}
