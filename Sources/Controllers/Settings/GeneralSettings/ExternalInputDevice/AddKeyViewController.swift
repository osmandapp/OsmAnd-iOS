//
//  AddKeyViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 15.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

protocol AddKeyDelegate: AnyObject {
    func setKey(_ keyCode: UIKeyboardHIDUsage)
}

final class AddKeyViewController: OABaseSettingsViewController {
    var deviceId: String?
    var action: OAQuickAction?
    var keyCodes: [UIKeyboardHIDUsage] = []
    weak var addKeyDelegate: AddKeyDelegate?
    
    override var canBecomeFirstResponder: Bool {
        true
    }
    
    private var saveButton: UIBarButtonItem?
    private var key: UIKeyboardHIDUsage?
    
    override func getTitle() -> String? {
        localizedString("add_button")
    }
    
    override func registerCells() {
        addCell(KeyTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        let keySection = tableData.createNewSection()
        let keyRow = keySection.createNewRow()
        keyRow.cellType = KeyTableViewCell.reuseIdentifier
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        guard let deviceId else { return nil }
        let actionName = action?.getName()
        let cell = tableView.dequeueReusableCell(withIdentifier: KeyTableViewCell.reuseIdentifier, for: indexPath) as! KeyTableViewCell
        var existedKeyActionName: String?
        if let key {
            if let foundAction = InputDevicesHelper.shared.getDeviceById(appMode, deviceId)?.findAction(with: key),
               foundAction.getType() != action?.getType() {
                existedKeyActionName = foundAction.getName()
            } else {
                existedKeyActionName = keyCodes.first(where: { $0 == key }).flatMap { _ in actionName }
            }
        }
        cell.configure(actionName: actionName, key: key, existedKeyActionName: existedKeyActionName, showDisableIfNeeded: existedKeyActionName != nil || keyCodes.contains(where: { $0 == key }), cornerRadius: 6)
        return cell
    }
    
    override func onRightNavbarButtonPressed() {
        guard let key else { return }
        addKeyDelegate?.setKey(key)
        dismiss()
    }
    
    override func getLeftNavbarButtonTitle() -> String? {
        localizedString("shared_string_cancel")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        saveButton = createRightNavbarButton(localizedString("shared_string_save"),
                                             iconName: nil,
                                             action: #selector(onRightNavbarButtonPressed),
                                             menu: nil)
        changeSaveButtonAvailability(isEnabled: false)
        return saveButton.flatMap { [$0] } ?? []
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if let key = press.key, let deviceId, self.key != key.keyCode {
                self.key = key.keyCode
                reloadDataWith(animated: true, completion: nil)
                if let foundAction = InputDevicesHelper.shared.getDeviceById(appMode, deviceId)?.findAction(with: key.keyCode),
                   foundAction.getType() != action?.getType() {
                    changeSaveButtonAvailability(isEnabled: false)
                } else {
                    changeSaveButtonAvailability(isEnabled: !keyCodes.contains(where: { $0 == key.keyCode }))
                }
            }
        }
        super.pressesBegan(presses, with: event)
    }
    
    private func changeSaveButtonAvailability(isEnabled: Bool) {
        changeButtonAvailability(saveButton, isEnabled: isEnabled)
    }
}
