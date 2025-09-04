//
//  MainExternalInputDeviceViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 25.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MainExternalInputDeviceViewController: OABaseSettingsViewController {
    private static let deviceRowKey = "deviceRowKey"
    private static let emptyStateRowKey = "emptyStateRowKey"
    private static let noExternalDeviceKey = "noExternalDeviceKey"
    private static let buttonTitleKey = "buttonTitleKey"
    private static let keyAssignmentKey = "keyAssignmentKey"
    
    private var keyAssignments: [KeyAssignment] = [KeyAssignment(action: MapZoomOutAction(), inputs: ["l", "p"]), KeyAssignment(action: MapZoomOutAction(), inputs: ["l"])] // TODO
    private var prevDefaultDevice: Bool = false
    private var isEditMode: Bool = false {
        didSet {
            tableView.setEditing(isEditMode, animated: true)
            updateUIAnimated(nil)
        }
    }
    private lazy var settingExternalInputDevice: InputDeviceProfile? = InputDeviceHelper.shared.getSelectedDevice(with: appMode)
    
    private var isDefaultDevice: Bool {
        settingExternalInputDevice?.getId() == NoneDeviceProfile.deviceId || settingExternalInputDevice?.getId() == KeyboardDeviceProfile.deviceId || settingExternalInputDevice?.getId() == WunderLINQDeviceProfile.deviceId
    }
    
    private var showToolbar: Bool {
        isDefaultDevice || keyAssignments.isEmpty
    }
    
    override func registerCells() {
        addCell(OAValueTableViewCell.reuseIdentifier)
        addCell(OALargeImageTitleDescrTableViewCell.reuseIdentifier)
        addCell(KeyAssignmentTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String? {
        localizedString("external_input_device")
    }
    
    override func generateData() {
        settingExternalInputDevice = InputDeviceHelper.shared.getSelectedDevice(with: appMode)
        guard let settingExternalInputDevice else { return }
        tableData.clearAllData()
        
        if prevDefaultDevice != isDefaultDevice {
            setupBottomButtons()
            prevDefaultDevice = isDefaultDevice
        }
        
        let externalInputDeviceValue = settingExternalInputDevice.toHumanString()
        let externalInputDeviceId = settingExternalInputDevice.getId()
        
        if !isEditMode {
            let deviceSection = tableData.createNewSection()
            let deviceRow = deviceSection.createNewRow()
            deviceRow.cellType = OAValueTableViewCell.reuseIdentifier
            deviceRow.key = Self.deviceRowKey
            deviceRow.title = localizedString("device")
            deviceRow.descr = externalInputDeviceValue
        }
        
        if keyAssignments.isEmpty || externalInputDeviceId == NoneDeviceProfile.deviceId {
            let noExternalDeviceSection = tableData.createNewSection()
            let noExternalDeviceRow = noExternalDeviceSection.createNewRow()
            noExternalDeviceRow.cellType = OALargeImageTitleDescrTableViewCell.reuseIdentifier
            noExternalDeviceRow.key = Self.emptyStateRowKey
            noExternalDeviceRow.title = externalInputDeviceId == NoneDeviceProfile.deviceId ? nil : localizedString("no_assigned_keys")
            noExternalDeviceRow.iconName = externalInputDeviceId == NoneDeviceProfile.deviceId ? "ic_custom_keyboard" : "ic_custom_keyboard_disabled"
            noExternalDeviceRow.iconTintColor = UIColor.iconColorDefault
            noExternalDeviceRow.descr = localizedString(externalInputDeviceId == NoneDeviceProfile.deviceId ? "select_to_use_an_external_input_device" : "no_assigned_keys_desc")
            noExternalDeviceRow.setObj(externalInputDeviceId == NoneDeviceProfile.deviceId, forKey: Self.noExternalDeviceKey)
            if externalInputDeviceId != NoneDeviceProfile.deviceId {
                noExternalDeviceRow.setObj(localizedString("shared_string_add"), forKey: Self.buttonTitleKey)
            }
        } else {
            let keyAssignmentsSection = tableData.createNewSection()
            if !isEditMode {
                keyAssignmentsSection.headerText = localizedString("key_assignments")
            }
            for keyAssignment in keyAssignments {
                let keyAssignmentRow = keyAssignmentsSection.createNewRow()
                keyAssignmentRow.cellType = KeyAssignmentTableViewCell.reuseIdentifier
                keyAssignmentRow.key = keyAssignment.getId()
                keyAssignmentRow.title = keyAssignment.getName()
                keyAssignmentRow.iconName = keyAssignment.getIcon()
                keyAssignmentRow.iconTintColor = appMode.getProfileColor()
                keyAssignmentRow.setObj(keyAssignment.getInputs(), forKey: Self.keyAssignmentKey)
            }
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
            cell.descriptionVisibility(false)
            cell.accessoryType = .disclosureIndicator
            cell.leftIconVisibility(false)
            cell.titleLabel.text = item.title
            cell.valueLabel.text = item.descr
            return cell
        } else if item.cellType == OALargeImageTitleDescrTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OALargeImageTitleDescrTableViewCell.reuseIdentifier, for: indexPath) as! OALargeImageTitleDescrTableViewCell
            let noExternalDevice = (item.obj(forKey: Self.noExternalDeviceKey) as? Bool) ?? false
            cell.selectionStyle = .none
            cell.showButton(!noExternalDevice)
            cell.showTitle(!noExternalDevice)
            cell.cellImageView?.image = UIImage.templateImageNamed(item.iconName)
            cell.cellImageView?.tintColor = item.iconTintColor
            cell.titleLabel?.text = item.title
            cell.titleLabel?.accessibilityLabel = item.title
            cell.titleLabel?.isHidden = noExternalDevice
            cell.descriptionLabel?.text = item.descr
            cell.descriptionLabel?.accessibilityLabel = item.descr
            if cell.needsUpdateConstraints() {
                cell.setNeedsUpdateConstraints()
            }
            if !noExternalDevice {
                cell.button?.setTitle(item.obj(forKey: Self.buttonTitleKey) as? String, for: .normal)
                cell.button?.accessibilityLabel = item.obj(forKey: Self.buttonTitleKey) as? String
                cell.button?.removeTarget(nil, action: nil, for: .allEvents)
                cell.button?.tag = indexPath.section << 10 | indexPath.row
                cell.button?.addTarget(self, action: #selector(onAddButtonClicked(sender:)), for: .touchUpInside)
            }
            return cell
        } else if item.cellType == KeyAssignmentTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: KeyAssignmentTableViewCell.reuseIdentifier, for: indexPath) as! KeyAssignmentTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.descriptionVisibility(false)
            cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
            cell.leftIconView.tintColor = item.iconTintColor
            cell.titleLabel.text = item.title
            cell.titleLabel.accessibilityLabel = item.title
            if let inputs = item.obj(forKey: Self.keyAssignmentKey) as? [String] {
                cell.configure(inputs: inputs)
            }
            return cell
        }
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        guard let tableData else { return }
        let item = tableData.item(for: indexPath)
        if item.key == Self.deviceRowKey {
            if let vc = OAProfileGeneralSettingsParametersViewController(type: EOAProfileGeneralSettingsExternalInputDevices, applicationMode: appMode) {
                vc.delegate = self
                show(vc)
            }
        } else if keyAssignments.contains(where: { $0.getId() == item.key }) {
            showKeyAssignment()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        isEditMode
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        // TODO
        keyAssignments.remove(at: indexPath.row)
        tableData.removeRow(at: indexPath)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.reloadData()
        updateBottomButtons()
        switchOffEditModeIfNoItems()
    }
    
    override func onLeftNavbarButtonPressed() {
        if isEditMode {
            switchEditMode(to: false)
        } else {
            super.onLeftNavbarButtonPressed()
        }
    }
    
    override func onRightNavbarButtonPressed() {
        switchEditMode(to: false)
    }
    
    override func onTopButtonPressed() {
        if isEditMode {
            showClearAllAlert()
        } else {
            showKeyAssignment()
        }
    }
    
    override func onBottomButtonPressed() {
        switchEditMode(to: true)
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        isEditMode ? localizedString("shared_string_cancel") : nil
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        isEditMode ? [createRightNavbarButton(localizedString("shared_string_done"), iconName: nil, action: #selector(onRightNavbarButtonPressed), menu: nil)] : []
    }
    
    override func getTopButtonTitle() -> String {
        showToolbar ? "" : localizedString(isEditMode ? "shared_string_clear_all" : "shared_string_add")
    }
    
    override func getBottomButtonTitle() -> String {
        showToolbar || isEditMode ? "" : localizedString("shared_string_edit")
    }
    
    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        .graySimple
    }
    
    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        .graySimple
    }
    
    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        .horizontal
    }
    
    override func onSettingsChanged() {
        super.onSettingsChanged()
        reloadDataWith(animated: true, completion: nil)
    }
    
    @objc private func onAddButtonClicked(sender: UIButton) {
        showKeyAssignment()
    }
    
    private func showKeyAssignment() {
        guard let vc = EditKeyAssignmentController() else { return }
        vc.delegate = self
        show(vc)
    }
    
    private func switchEditMode(to on: Bool) {
        isEditMode = on
    }
    
    private func switchOffEditModeIfNoItems() {
        guard keyAssignments.isEmpty else { return }
        switchEditMode(to: false)
    }
    
    private func showClearAllAlert() {
        let alert = UIAlertController(title: localizedString("clear_all_key_shortcuts"), message: localizedString("clear_all_key_shortcuts_summary"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_remove"), style: .destructive, handler: { _ in
            self.clearAll()
        }))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        alert.popoverPresentationController?.sourceView = view
        present(alert, animated: true)
    }
    
    private func clearAll() {
        // TODO
        keyAssignments.removeAll()
        reloadDataWith(animated: true, completion: nil)
        updateBottomButtons()
        switchOffEditModeIfNoItems()
    }
}
