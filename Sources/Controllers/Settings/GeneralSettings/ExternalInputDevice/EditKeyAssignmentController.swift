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
    
    private var isEditMode: Bool = false {
        didSet {
            tableView.setEditing(isEditMode, animated: true)
            updateUIAnimated(nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsSelectionDuringEditing = true
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
            return keyAssignment?.getName()
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
            addActionRow.iconName = "ic_custom_plus"
        }
        
        let assignedKeysSection = tableData.createNewSection()
        assignedKeysSection.headerText = localizedString("assigned_keys")
        if isAdd || isEditMode {
            for keyCode in keyCodes {
                let editAssignedKeysRow = assignedKeysSection.createNewRow()
                editAssignedKeysRow.cellType = KeyAssignmentTableViewCell.reuseIdentifier
                editAssignedKeysRow.title = String(format: localizedString("key_name_pattern"), KeySymbolMapper.getKeySymbol(for: keyCode))
            }
            
            let addKeyRow = assignedKeysSection.createNewRow()
            addKeyRow.cellType = OASimpleTableViewCell.reuseIdentifier
            addKeyRow.key = Self.addKeyKey
            addKeyRow.title = localizedString("key_assignment_add_key")
            addKeyRow.iconName = "ic_custom_plus"
        } else if let keyAssignment {
            let assignedKeysRow = assignedKeysSection.createNewRow()
            assignedKeysRow.cellType = KeyAssignmentTableViewCell.reuseIdentifier
            assignedKeysRow.key = Self.assignedKeysRowKey
            assignedKeysRow.setObj(keyAssignment.getKeyCodes(), forKey: Self.assignedKeysKey)
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == KeyAssignmentTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: KeyAssignmentTableViewCell.reuseIdentifier, for: indexPath) as! KeyAssignmentTableViewCell
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
        } else if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
            cell.descriptionVisibility(false)
            if item.key == Self.actionKey {
                cell.selectionStyle = .none
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
                cell.leftIconView.tintColor = item.iconTintColor
            } else {
                cell.selectionStyle = .default
                cell.leftIconView.image = item.iconName.flatMap(UIImage.init(named:))?.withRenderingMode(.alwaysOriginal)
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
        } else if item.key == Self.addKeyKey {
            show(AddKeyViewController())
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
            if isAdd || actionToRemove != nil {
                action = nil
            } else if actionToRemove == nil {
                actionToRemove = action
            }
            changeRightNavButtonAvailability(isEnabled: false)
            reloadDataWith(animated: true, completion: nil)
        }
    }
    
    override func onLeftNavbarButtonPressed() {
        if isEditMode {
            if let actionToRemove {
                action = actionToRemove
            }
            actionToRemove = nil
            switchEditMode(to: false)
        } else {
            super.onLeftNavbarButtonPressed()
        }
    }
    
    override func onRightNavbarButtonPressed() {
        if isEditMode, let deviceId, let keyAssignmentId = keyAssignment?.getId(), let action {
            InputDevicesHelper.shared.updateAssignment(with: appMode, deviceId: deviceId, assignmentId: keyAssignmentId, action: action, keyCodes: keyCodes)
            delegate.onSettingsChanged()
            actionToRemove = nil
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
            changeRightNavButtonAvailability(isEnabled: action != nil)
        }
        return rightNavButton.flatMap { [$0] } ?? []
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
    
    private func changeRightNavButtonAvailability(isEnabled: Bool) {
        changeButtonAvailability(rightNavButton, isEnabled: isEnabled)
    }
}

extension EditKeyAssignmentController: OAEditKeyAssignmentDelegate {
    func setKeyAssignemntAction(_ action: OAQuickAction) {
        self.action = action
        reloadDataWith(animated: true, completion: nil)
        changeRightNavButtonAvailability(isEnabled: true)
    }
}
