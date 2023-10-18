//
//  BLEChangeDeviceNameViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 17.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class BLEChangeDeviceNameViewController: OABaseNavbarViewController {
    var device: Device!
    var onSaveAction: (() -> Void)? = nil
    
    private var textView: UITextView?
    private var newDeviceName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newDeviceName = device.deviceName
        generateData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView?.becomeFirstResponder()
    }
    
    override func getTitle() -> String! {
        "Name"
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_close")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        let saveBarButton = createRightNavbarButton(localizedString("shared_string_save"), iconName: nil, action: #selector(onLeftNavbarButtonPressed), menu: nil)
        return [saveBarButton!]
    }
    
    override func onRightNavbarButtonPressed() {
        if newDeviceName != device.deviceName {
            device.deviceName = newDeviceName
            DeviceHelper.shared.changeDeviceName(with: device.id, name: newDeviceName)
            onSaveAction?()
        }
        dismiss()
    }
    
    override func onLeftNavbarButtonPressed() {
        dismiss()
    }
    
    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        let name = section.createNewRow()
        
        name.cellType = OATextMultilineTableViewCell.getIdentifier()
        name.key = "name_key"
        name.title = newDeviceName
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        if item.cellType == OATextMultilineTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OATextMultilineTableViewCell.getIdentifier()) as? OATextMultilineTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OATextMultilineTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OATextMultilineTableViewCell
                cell?.leftIconVisibility(false)
                cell?.textView.isUserInteractionEnabled = true
                cell?.textView.isEditable = true
                cell?.textView.delegate = self
                cell?.textView.returnKeyType = .done
                cell?.textView.enablesReturnKeyAutomatically = true
            }
            if let cell {
                textView = cell.textView
                cell.textView.text = item.title
                cell.clearButton.removeTarget(nil, action: nil, for: .touchUpInside)
                cell.clearButton.addTarget(self, action: #selector(onClearButtonPressed), for: .touchUpInside)
                cell.clearButton.tintColor = UIColor.buttonBgColorDisabled
            }
            outCell = cell
        }
        return outCell
    }
    
    @objc private func onClearButtonPressed() {
        newDeviceName = ""
        generateData()
        tableView.reloadData()
        navigationItem.setRightBarButtonItems(isEnabled: false, with: UIColor.buttonBgColorDisabled)
    }
}

private extension UINavigationItem {
    func setRightBarButtonItems(isEnabled: Bool, with tintColor: UIColor? = nil) {
        rightBarButtonItems?.forEach {
            if let button = $0.customView as? UIButton {
                $0.isEnabled = isEnabled
                button.isEnabled = isEnabled
                button.tintColor = tintColor
                button.setTitleColor(tintColor, for: .normal)
            }
        }
    }
}

extension BLEChangeDeviceNameViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        updateFileNameFromEditText(name: textView.text)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false;
        }
        return true;
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    private func updateFileNameFromEditText(name: String) {
        let text = name.trimmingCharacters(in: .whitespacesAndNewlines)
        navigationItem.setRightBarButtonItems(isEnabled: false, with: UIColor.buttonBgColorDisabled)
        if !text.isEmpty {
            newDeviceName = text
            navigationItem.setRightBarButtonItems(isEnabled: true, with: UIColor.buttonBgColorPrimary)
        }
    }
}
