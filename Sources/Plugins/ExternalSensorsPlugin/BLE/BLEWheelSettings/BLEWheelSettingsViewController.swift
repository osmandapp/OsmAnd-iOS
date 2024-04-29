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
    var device: Device!
    var onSaveAction: (() -> Void)?
    
    private var textField: UITextField? {
        didSet {
            textField?.keyboardType = .numberPad
        }
    }

    private var wheelSizeString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        wheelSizeString = wheelSize.cleanValue
        generateData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField?.becomeFirstResponder()
    }
    
    override func getTitle() -> String {
        localizedString("wheel_circumference")
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_cancel")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        let saveBarButton = createRightNavbarButton(localizedString("shared_string_apply"), iconName: nil, action: #selector(onRightNavbarButtonPressed), menu: nil)
        return [saveBarButton!]
    }
    
    override func onRightNavbarButtonPressed() {
        guard wheelSizeString != String(wheelSize),
              Float(wheelSizeString) != nil else {
            return
        }
        DeviceHelper.shared.changeDeviceParameter(with: device.id,
                                                  key: WheelDeviceSettings.WHEEL_CIRCUMFERENCE_KEY,
                                                  value: wheelSizeString)
        onSaveAction?()
        dismiss()
    }
    
    override func onLeftNavbarButtonPressed() {
        dismiss()
    }
    
    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        let name = section.createNewRow()
        name.cellType = OAInputTableViewCell.getIdentifier()
        name.key = "name_key"
        name.title = wheelSizeString
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell?
        if item.cellType == OAInputTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OAInputTableViewCell.getIdentifier()) as? OAInputTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OAInputTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OAInputTableViewCell
                cell?.leftIconVisibility(false)
                cell?.inputField.isUserInteractionEnabled = true
                cell?.inputField.delegate = self
                cell?.inputField.returnKeyType = .done
                cell?.inputField.enablesReturnKeyAutomatically = true
            }
            if let cell {
                textField = cell.inputField
                cell.clearButtonVisibility(false)
                cell.titleLabel.text = localizedString("shared_string_millimeters")
                cell.inputField.text = item.title
                cell.clearButton.removeTarget(nil, action: nil, for: .touchUpInside)
                cell.clearButton.addTarget(self, action: #selector(onClearButtonPressed), for: .touchUpInside)
                cell.clearButton.tintColor = UIColor.buttonBgColorDisabled
            }
            outCell = cell
        }
        return outCell
    }
    
    private func updateFileNameFromEditText(name: String) {
        let text = name.trimmingCharacters(in: .whitespacesAndNewlines)
        navigationItem.setRightBarButtonItems(isEnabled: false, with: UIColor.buttonBgColorDisabled)
        if !text.isEmpty {
            wheelSizeString = text
            navigationItem.setRightBarButtonItems(isEnabled: true, with: UIColor.iconColorActive)
        }
    }
    
    @objc private func onClearButtonPressed() {
        wheelSizeString = ""
        generateData()
        tableView.reloadData()
        navigationItem.setRightBarButtonItems(isEnabled: false, with: UIColor.buttonBgColorDisabled)
    }
}

extension BLEWheelSettingsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let currentText = textField.text, let textRange = Range(range, in: currentText) {
            let updatedText = currentText.replacingCharacters(in: textRange, with: string)
            updateFileNameFromEditText(name: updatedText)
        }
        
        return true
    }
}

private extension Float {
    var cleanValue: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}
