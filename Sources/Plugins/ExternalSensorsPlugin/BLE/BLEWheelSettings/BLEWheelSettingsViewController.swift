//
//  BLEWheelSettingsViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 14.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class BLEWheelSettingsViewController: OABaseNavbarViewController {
    var wheelSize: Float!
    var onSaveAction: (() -> Void)?
    
    private var textView: UITextView? {
        didSet {
            textView?.keyboardType = .namePhonePad
        }
    }
    private var wheelSizeString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        wheelSizeString = String(wheelSize)
        generateData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView?.becomeFirstResponder()
    }
    
    override func getTitle() -> String {
        localizedString("wheel_circumference")
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_close")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        let saveBarButton = createRightNavbarButton(localizedString("shared_string_save"), iconName: nil, action: #selector(onRightNavbarButtonPressed), menu: nil)
        return [saveBarButton!]
    }
    
    override func onRightNavbarButtonPressed() {
        if wheelSizeString != String(wheelSize) {
            // TODO: need ui design
          //  device.deviceName = wheelSizeString
           // DeviceHelper.shared.changeDeviceName(with: device.id, name: newDeviceName)
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
        name.title = wheelSizeString
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
        wheelSizeString = ""
        generateData()
        tableView.reloadData()
        navigationItem.setRightBarButtonItems(isEnabled: false, with: UIColor.buttonBgColorDisabled)
    }
}

extension BLEWheelSettingsViewController: UITextViewDelegate {
    
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
            wheelSizeString = text
            navigationItem.setRightBarButtonItems(isEnabled: true, with: UIColor.buttonBgColorPrimary)
        }
    }
}
