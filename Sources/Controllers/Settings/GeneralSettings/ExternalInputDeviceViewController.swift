//
//  ExternalInputDeviceViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 25.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ExternalInputDeviceViewController: OABaseSettingsViewController {
    private static let deviceRowKey = "deviceRowKey"
    private static let emptyStateRowKey = "emptyStateRowKey"
    
    override func registerCells() {
        addCell(OAValueTableViewCell.reuseIdentifier)
        addCell(OALargeImageTitleDescrTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String? {
        localizedString("external_input_device")
    }
    
    override func generateData() {
        tableData.clearAllData()
        let settingExternalInputDevice = OAAppSettings.sharedManager().settingExternalInputDevice.get(appMode)
        
        var externalInputDeviceValue = ""
        if settingExternalInputDevice == GENERIC_EXTERNAL_DEVICE {
            externalInputDeviceValue = localizedString("sett_generic_ext_input")
        } else if settingExternalInputDevice == WUNDERLINQ_EXTERNAL_DEVICE {
            externalInputDeviceValue = localizedString("sett_wunderlinq_ext_input")
        } else {
            externalInputDeviceValue = localizedString("shared_string_none")
        }

        let deviceSection = tableData.createNewSection()
        let deviceRow = deviceSection.createNewRow()
        deviceRow.cellType = OAValueTableViewCell.reuseIdentifier
        deviceRow.key = Self.deviceRowKey
        deviceRow.title = localizedString("device")
        deviceRow.descr = externalInputDeviceValue
        
        if settingExternalInputDevice == NO_EXTERNAL_DEVICE {
            let noExternalDeviceSection = tableData.createNewSection()
            let noExternalDeviceRow = noExternalDeviceSection.createNewRow()
            noExternalDeviceRow.cellType = OALargeImageTitleDescrTableViewCell.reuseIdentifier
            noExternalDeviceRow.key = Self.emptyStateRowKey
            noExternalDeviceRow.iconName = "ic_custom_keyboard"
            noExternalDeviceRow.iconTintColor = UIColor.iconColorDefault
            noExternalDeviceRow.descr = localizedString("select_to_use_an_external_input_device")
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
            cell.selectionStyle = .none
            cell.showButton(false)
            cell.showTitle(false)
            cell.cellImageView?.image = UIImage.templateImageNamed(item.iconName)
            cell.cellImageView?.tintColor = item.iconTintColor
            cell.titleLabel?.text = item.title
            cell.titleLabel?.accessibilityLabel = item.title
            cell.titleLabel?.isHidden = item.title == nil || item.title?.isEmpty == true
            cell.descriptionLabel?.text = item.descr
            cell.descriptionLabel?.accessibilityLabel = item.descr
            if cell.needsUpdateConstraints() {
                cell.setNeedsUpdateConstraints()
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
        }
    }
    
    override func onSettingsChanged() {
        super.onSettingsChanged()
        reloadDataWith(animated: true, completion: nil)
    }
}
