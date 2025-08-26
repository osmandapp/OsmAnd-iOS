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
    
    override func registerCells() {
        addCell(OAValueTableViewCell.reuseIdentifier)
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
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
        cell.descriptionVisibility(false)
        cell.accessoryType = .disclosureIndicator
        cell.leftIconVisibility(false)
        cell.titleLabel.text = item.title
        cell.valueLabel.text = item.descr
        return cell
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        guard let tableData else { return }
        let item = tableData.item(for: indexPath)
        let vc = OAProfileGeneralSettingsParametersViewController(type: EOAProfileGeneralSettingsExternalInputDevices, applicationMode: appMode)
        vc?.delegate = self
        vc.flatMap(show)
    }
    
    override func onSettingsChanged() {
        super.onSettingsChanged()
        reloadDataWith(animated: true, completion: nil)
    }
}
