//
//  BLEDescriptionViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.10.2023.
//

import UIKit

final class BLEDescriptionViewController: OABaseNavbarViewController {
    
    private enum SectionKey: String {
        case deviceHeader, information, receivedData, settings, forgetSensor
    }
    
    private static let estimatedRowHeight: CGFloat = 66

    var device: Device! {
        didSet {
            device.didChangeCharacteristic = { [weak self] in
                guard let self else { return }
                headerView.updateActiveServiceImage()
                generateData()
                tableView.reloadData()
            }
            device.didDisconnect = { [weak self, weak device] in
                guard let self, let device else { return }
                headerView.configure(device: device)
                generateData()
                tableView.reloadData()
            }
        }
    }
    
    var wheelSizeInMillimeters: Float?
    
    private lazy var headerView: DescriptionDeviceHeader = {
        Bundle.main.loadNibNamed("DescriptionDeviceHeader", owner: self, options: nil)?[0] as! DescriptionDeviceHeader
    }()

    private lazy var widgetTypesByFieldName: [String: WidgetType] = [
        localizedString("external_device_characteristic_speed"): .bicycleSpeed,
        localizedString("external_device_characteristic_cadence"): .bicycleCadence,
        localizedString("map_widget_ant_heart_rate"): .heartRate,
        localizedString("shared_string_temperature"): .temperature
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Self.estimatedRowHeight

        headerView.configure(device: device)
        headerView.didPairedDeviceAction = { [weak self] in
            guard let self else { return }
            generateData()
            tableView.reloadData()
        }
        registerObservers()
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func registerCells() {
        tableView.register(DescriptionDeviceCell.self, forCellReuseIdentifier: DescriptionDeviceCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        let headerSection = tableData.createNewSection()
        headerSection.key = SectionKey.deviceHeader.rawValue
        let headerRow = headerSection.createNewRow()
        headerRow.cellType = DescriptionDeviceCell.reuseIdentifier
        headerRow.key = SectionKey.deviceHeader.rawValue
        
        if DeviceHelper.shared.isPairedDevice(id: device.id) {
            // Information
            if let sensor = device.sensors.compactMap({ $0 as? BLEBatterySensor }).first {
                let infoSection = tableData.createNewSection()
                infoSection.headerText = localizedString("external_device_details_information").uppercased()
                infoSection.key = SectionKey.information.rawValue
                let batteryRow = infoSection.createNewRow()
                batteryRow.cellType = OAValueTableViewCell.getIdentifier()
                batteryRow.key = "battery_row"
                batteryRow.title = localizedString("external_device_details_battery")
                let batteryLevel = sensor.lastBatteryData.batteryLevel
                batteryRow.descr = if device.isConnected, batteryLevel != -1 {
                    NumberFormatter.percentFormatter.string(from: (Double(batteryLevel) / 100.0) as NSNumber) ?? "-"
                } else {
                    "-"
                }
            }
            // Received Data
            if let receivedData = device.getDataFields, !receivedData.isEmpty {
                let receivedDataSection = tableData.createNewSection()
                receivedDataSection.headerText = localizedString("external_device_details_received_data").uppercased()
                receivedDataSection.key = SectionKey.receivedData.rawValue
                for array in receivedData {
                    if let dic = array.first {
                        let row = receivedDataSection.createNewRow()
                        row.cellType = OAValueTableViewCell.getIdentifier()
                        row.key = "row"
                        row.title = dic.key
                        row.descr = actualDataValue(fieldName: dic.key, value: dic.value)
                    }
                }
            }
            // Settings
            let settingsSection = tableData.createNewSection()
            settingsSection.headerText = localizedString("shared_string_settings").uppercased()
            settingsSection.key = SectionKey.settings.rawValue
            let nameRow = settingsSection.createNewRow()
            nameRow.cellType = OAValueTableViewCell.getIdentifier()
            nameRow.key = "name_row"
            nameRow.title = localizedString("shared_string_name")
            nameRow.descr = device?.deviceName ?? ""
            
            if let settingsDataDict = device.getSettingsFields, !settingsDataDict.isEmpty {
                for (key, value) in settingsDataDict {
                    let settingRow = settingsSection.createNewRow()
                    settingRow.cellType = OAValueTableViewCell.getIdentifier()
                    settingRow.key = key
                    if key == WheelDeviceSettings.WHEEL_CIRCUMFERENCE_KEY {
                        settingRow.title = localizedString("wheel_circumference")
                    }
                    if let floatValue = value as? Float {
                        if key == WheelDeviceSettings.WHEEL_CIRCUMFERENCE_KEY {
                            wheelSizeInMillimeters = floatValue
                        }
                        settingRow.descr = String(format: "%.0f", floatValue) + " " + localizedString("shared_string_millimeters_short")
                    }
                 }
            }
            
            let forgetSensorSection = tableData.createNewSection()
            forgetSensorSection.key = SectionKey.forgetSensor.rawValue
            let forgetSensorRow = forgetSensorSection.createNewRow()
            forgetSensorRow.cellType = OAValueTableViewCell.getIdentifier()
            forgetSensorRow.key = "forget_sensor_row"
            forgetSensorRow.title = localizedString("external_device_forget_sensor")
        } else {
            tableView.sectionHeaderTopPadding = 0
            let footerSection = tableData.createNewSection()
            footerSection.footerText = localizedString("external_device_unpair_description")
        }
        tableData.resetChanges()
    }
    
    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        let key = tableData.sectionData(for: UInt(section)).key
        if key == SectionKey.deviceHeader.rawValue {
            return .leastNonzeroMagnitude
        }
        if key == SectionKey.forgetSensor.rawValue {
            return 34
        }
        if !DeviceHelper.shared.isPairedDevice(id: device.id) {
            return .leastNonzeroMagnitude
        }
        return 56
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let key = tableData.sectionData(for: UInt(section)).key
        if key == SectionKey.deviceHeader.rawValue {
            return .leastNonzeroMagnitude
        }
        return DeviceHelper.shared.isPairedDevice(id: device.id) ? .leastNonzeroMagnitude : UITableView.automaticDimension
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == DescriptionDeviceCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: DescriptionDeviceCell.reuseIdentifier, for: indexPath) as! DescriptionDeviceCell
            cell.configure(header: headerView)
            return cell
        }
        if item.cellType == OAValueTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.getIdentifier()) as? OAValueTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OAValueTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OAValueTableViewCell
                cell?.descriptionVisibility(false)
                cell?.leftIconVisibility(false)
            }
            if let cell {
                cell.separatorInset = .zero
                cell.valueLabel.text = item.descr
                cell.titleLabel.text = item.title
                let sectionKey = tableData.sectionData(for: UInt(indexPath.section)).key
                if sectionKey == SectionKey.information.rawValue || sectionKey == SectionKey.receivedData.rawValue {
                    cell.selectionStyle = .none
                    cell.accessoryType = .none
                    cell.titleLabel.textColor = UIColor.textColorPrimary
                } else if sectionKey == SectionKey.settings.rawValue {
                    cell.selectionStyle = .gray
                    cell.accessoryType = .disclosureIndicator
                    cell.titleLabel.textColor = UIColor.textColorPrimary
                } else if sectionKey == SectionKey.forgetSensor.rawValue {
                    cell.selectionStyle = .gray
                    cell.accessoryType = .none
                    cell.titleLabel.textColor = UIColor.buttonBgColorDisruptive
                }
            }
            return cell
        }
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if item.key == "forget_sensor_row" {
            showForgetSensorActionSheet()
        } else if item.key == "name_row" {
            let nameVC = BLEChangeDeviceNameViewController()
            nameVC.device = device
            nameVC.onSaveAction = { [weak self] in
                guard let self else { return }
                headerView.configure(device: device)
                generateData()
                tableView.reloadData()
            }
            navigationController?.present(UINavigationController(rootViewController: nameVC), animated: true)
        } else if item.key == WheelDeviceSettings.WHEEL_CIRCUMFERENCE_KEY {
            let wheelVC = BLEWheelSettingsViewController()
            wheelVC.device = device
            wheelVC.wheelSize = wheelSizeInMillimeters
            wheelVC.onSaveAction = { [weak self] in
                guard let self else { return }
                generateData()
                tableView.reloadData()
            }
            navigationController?.present(UINavigationController(rootViewController: wheelVC), animated: true)
        }
    }
    
    override func registerObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceRSSIUpdated),
                                               name: .deviceRSSIUpdated,
                                               object: nil)
    }
    
    private func actualDataValue(fieldName: String, value: String) -> String {
        guard device.isConnected else { return "-" }
        guard value != "-",
              let widgetType = widgetTypesByFieldName[fieldName],
              let sensor = device.sensors.first(where: { $0.getSupportedWidgetDataFieldTypes()?.contains(widgetType) == true }),
              !sensor.hasActualData(for: widgetType),
              let dataList = sensor.getLastSensorDataList(for: widgetType),
              let field = dataList.lazy.compactMap({ $0.getWidgetField(fieldType: widgetType) }).first,
              let unit = field.getFormattedValue()?.unit,
              !unit.isEmpty else {
            return value
        }
        return "0 " + unit
    }
    
    @objc private func deviceRSSIUpdated() {
        headerView.updateRSSI(with: device.rssi)
    }
}

extension BLEDescriptionViewController {
    private func showForgetSensorActionSheet() {
        let alert = UIAlertController(title: device.deviceName, message: localizedString("external_device_forget_sensor_description"), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: localizedString("external_device_forget_sensor"), style: .destructive, handler: { [weak self] _ in
            guard let self else { return }
            DeviceHelper.shared.setDevicePaired(device: device, isPaired: false)
            navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        alert.popoverPresentationController?.sourceView = view
        present(alert, animated: true)
    }
}
