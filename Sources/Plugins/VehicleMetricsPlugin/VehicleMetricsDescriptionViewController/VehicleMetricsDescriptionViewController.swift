//
//  VehicleMetricsDescriptionViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 19.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class VehicleMetricsDescriptionViewController: OABaseNavbarViewController {
    
    enum TableViewStartBehavior {
        case normal, scrollToSearch
    }
    
    private enum SectionKey: String {
        case deviceHeader, vehicleInfo, receivedData, settings, forgetSensor
    }
    
    static let placeholderTextNA: String = "N/A"
    private static let estimatedRowHeight: CGFloat = 66
    
    var startBehavior: TableViewStartBehavior = .normal
    
    var hasWidgetItem = false
    
    // swiftlint:disable all
    var device: Device! {
        didSet {
            device.didChangeCharacteristic = { [weak self] in
                guard let self else { return }
                headerView.updateActiveServiceImage()
                if hasWidgetItem {
                    updateVisibleReceivedDataCells()
                } else {
                    generateData()
                    tableView.reloadData()
                }
            }
            device.didDisconnect = { [weak self, weak device] in
                guard let self, let device else { return }
                headerView.configure(device: device)
                hasWidgetItem = false
                // fill row N/A description
                generateData()
                tableView.reloadData()
            }
        }
    }
    // swiftlint:enable all
    
    private var plugin: VehicleMetricsPlugin?
    
    private lazy var headerView: DescriptionDeviceHeader = {
        let header = Bundle.main.loadNibNamed("DescriptionDeviceHeader", owner: self, options: nil)?[0] as! DescriptionDeviceHeader
        header.showSignalIndicator(show: false)
        return header
    }()
    
    private lazy var widgets: [OBDDataComputer.OBDTypeWidget] = [.fuelType,
                                                                 .temperatureIntake,
                                                                 .temperatureAmbient,
                                                                 .temperatureCoolant,
                                                                 .engineOilTemperature,
                                                                 .rpm,
                                                                 .speed,
                                                                 fuelConsumptionRate(),
                                                                 .fuelLeftLiter,
                                                                 .calculatedEngineLoad,
                                                                 .fuelPressure,
                                                                 .throttlePosition,
                                                                 .batteryVoltage,
                                                                 .adapterBatteryVoltage]
    
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
        plugin = OAPluginsHelper.getEnabledPlugin(VehicleMetricsPlugin.self) as? VehicleMetricsPlugin
        
        // NOTE: to debug obd simulator
        /*
         OBDService.shared.startDispatcher()
         DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
         self?.generateData()
         self?.tableView.reloadData()
         }
         */
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if case .scrollToSearch = startBehavior {
            startBehavior = .normal
            scrollToSearchSection()
        }
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func registerCells() {
        tableView.register(DescriptionDeviceCell.self, forCellReuseIdentifier: DescriptionDeviceCell.reuseIdentifier)
        addCell(OAValueTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        let headerSection = tableData.createNewSection()
        headerSection.key = SectionKey.deviceHeader.rawValue
        let headerRow = headerSection.createNewRow()
        headerRow.cellType = DescriptionDeviceCell.reuseIdentifier
        headerRow.key = SectionKey.deviceHeader.rawValue
        
        if DeviceHelper.shared.isPairedDevice(id: device.id) {
            // Vehicle info
            let vehicleInfoSection = tableData.createNewSection()
            vehicleInfoSection.headerText = localizedString("obd_vehicle_info").uppercased()
            vehicleInfoSection.footerText = localizedString("obd_vin_desc")
            vehicleInfoSection.key = SectionKey.vehicleInfo.rawValue
            
            let vinRow = vehicleInfoSection.createNewRow()
            vinRow.cellType = OAValueTableViewCell.reuseIdentifier
            vinRow.key = "vin"
            vinRow.title = localizedString("obd_vin")
            
            if let vin = OBDDataComputer.shared.widgets.first(where: { $0.type == .vin }) {
                vinRow.descr = description(for: vin)
                vinRow.setObj(vin, forKey: "widgetItem")
            } else {
                vinRow.descr = Self.placeholderTextNA
            }
            
            // Received Data
            let receivedDataSection = tableData.createNewSection()
            receivedDataSection.headerText = localizedString("external_device_details_received_data").uppercased()
            receivedDataSection.key = SectionKey.receivedData.rawValue
            
            for widget in widgets {
                let row = receivedDataSection.createNewRow()
                row.cellType = OAValueTableViewCell.reuseIdentifier
                row.icon = widget.image
                row.key = "row"
                row.title = widget.getTitle()
                
                guard let dataItem = OBDDataComputer.shared.widgets.first(where: { $0.type == widget }) else {
                    debugPrint("widget is empty")
                    row.descr = Self.placeholderTextNA
                    continue
                }
                hasWidgetItem = true
                row.setObj(dataItem, forKey: "widgetItem")
            }
            
            // Settings
            let settingsSection = tableData.createNewSection()
            settingsSection.headerText = localizedString("shared_string_settings").uppercased()
            settingsSection.key = SectionKey.settings.rawValue
            
            let nameRow = settingsSection.createNewRow()
            nameRow.cellType = OAValueTableViewCell.reuseIdentifier
            nameRow.key = "name_row"
            nameRow.title = localizedString("shared_string_name")
            nameRow.descr = device.deviceName
            
            let forgetSensorSection = tableData.createNewSection()
            forgetSensorSection.key = SectionKey.forgetSensor.rawValue
            let forgetSensorRow = forgetSensorSection.createNewRow()
            forgetSensorRow.cellType = OAValueTableViewCell.reuseIdentifier
            forgetSensorRow.key = "forget_sensor_row"
            forgetSensorRow.title = localizedString("external_device_forget_sensor")
        } else {
            tableView.sectionHeaderTopPadding = 0
            let footerSection = tableData.createNewSection()
            footerSection.footerText = localizedString("external_device_unpair_description")
        }
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
        if item.cellType == OAValueTableViewCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as? OAValueTableViewCell else {
                return nil
            }
            cell.descriptionVisibility(false)
            cell.separatorInset = .zero
            cell.titleLabel.text = item.title
            let sectionKey = tableData.sectionData(for: UInt(indexPath.section)).key
            if sectionKey == SectionKey.receivedData.rawValue || sectionKey == SectionKey.vehicleInfo.rawValue {
                if let widgetItem = item.obj(forKey: "widgetItem") as? OBDDataComputer.OBDComputerWidget {
                    cell.valueLabel.text = description(for: widgetItem)
                } else {
                    cell.valueLabel.text = item.descr
                }
            } else {
                cell.valueLabel.text = item.descr
            }
            if sectionKey == SectionKey.receivedData.rawValue || sectionKey == SectionKey.vehicleInfo.rawValue {
                cell.leftIconVisibility(sectionKey == SectionKey.receivedData.rawValue)
                cell.imageView?.image = item.icon
                cell.selectionStyle = .none
                cell.accessoryType = .none
                cell.titleLabel.textColor = .textColorPrimary
            } else if sectionKey == SectionKey.settings.rawValue {
                cell.leftIconVisibility(false)
                cell.imageView?.image = nil
                cell.selectionStyle = .gray
                cell.accessoryType = .disclosureIndicator
                cell.titleLabel.textColor = .textColorPrimary
            } else if sectionKey == SectionKey.forgetSensor.rawValue {
                cell.leftIconVisibility(false)
                cell.imageView?.image = nil
                cell.selectionStyle = .gray
                cell.accessoryType = .none
                cell.titleLabel.textColor = .buttonBgColorDisruptive
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
        }
    }
    
    private func fuelConsumptionRate() -> OBDDataComputer.OBDTypeWidget {
        OAAppSettings.sharedManager().volumeUnits.get() == .LITRES ? .fuelConsumptionRateLiterKm : .fuelConsumptionRateMPerLiter
    }
    
    private func description(for widget: OBDDataComputer.OBDComputerWidget) -> String {
        guard device.isConnected else {
            return Self.placeholderTextNA
        }
        
        guard let widgetItem = OBDDataComputer.shared.widgets.first(where: { $0.type == widget.type }) else {
            return Self.placeholderTextNA
        }
        
        let value = plugin?.getWidgetValue(computerWidget: widgetItem) ?? Self.placeholderTextNA
        
        guard value != Self.placeholderTextNA && value != "-" else {
            return value
        }
        
        let unit = plugin?.getWidgetUnit(widgetItem.type)
        let description = (unit?.isEmpty ?? true) ? value : "\(value) \(unit ?? "")"

        if widget.type == .vin {
            let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedDescription.isEmpty ? Self.placeholderTextNA : trimmedDescription
        }

        return description
    }
    
    private func updateVisibleReceivedDataCells() {
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else { return }
        
        for indexPath in visibleIndexPaths {
            let sectionData = tableData.sectionData(for: UInt(indexPath.section))
            
            guard sectionData.key == SectionKey.receivedData.rawValue || sectionData.key == SectionKey.vehicleInfo.rawValue else { continue }
            guard let cell = tableView.cellForRow(at: indexPath) as? OAValueTableViewCell else { continue }
            
            let item = tableData.item(for: indexPath)
            
            if let widgetItem = item.obj(forKey: "widgetItem") as? OBDDataComputer.OBDComputerWidget {
                cell.valueLabel.text = description(for: widgetItem)
            } else {
                cell.valueLabel.text = item.descr
            }
        }
    }
    
    private func scrollToSearchSection() {
        for index in 0..<tableData.sectionCount() {
            let section = tableData.sectionData(for: index)
            if section.key == SectionKey.settings.rawValue {
                let indexPath = IndexPath(row: 0, section: Int(index))
                tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                break
            }
        }
    }
}

extension VehicleMetricsDescriptionViewController {
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
