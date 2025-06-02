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
    
    private enum Section: Int {
        case vehicleInfo, receivedData, settings, forgetSensor
        
        var key: String {
            String(describing: self)
        }
    }
    
    static let widgets: [OBDDataComputer.OBDTypeWidget] = [.fuelType,
                                                           .temperatureIntake,
                                                           .temperatureAmbient,
                                                           .temperatureCoolant,
                                                           .engineOilTemperature,
                                                           .rpm,
                                                           .speed,
                                                           .fuelConsumptionRateLiterHour,
                                                           .fuelConsumptionRateLiterKm,
                                                           .fuelLeftLiter,
                                                           .calculatedEngineLoad,
                                                           .fuelPressure,
                                                           .throttlePosition,
                                                           .batteryVoltage]
    
    var startBehavior: TableViewStartBehavior = .normal
    
    // swiftlint:disable all
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
            }
        }
    }
    // swiftlint:enable all
    
    private lazy var headerView: DescriptionDeviceHeader = {
       let header = Bundle.main.loadNibNamed("DescriptionDeviceHeader", owner: self, options: nil)?[0] as! DescriptionDeviceHeader
        header.showSignalIndicator(show: false)
        return header
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        
        configureHeader()
        headerView.configure(device: device)
        headerView.didPairedDeviceAction = { [weak self] in
            guard let self else { return }
            generateData()
            tableView.reloadData()
        }
        tableView.tableHeaderView = headerView
        
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
    
    override func setupTableHeaderView() {
        configureHeader()
    }
    
    override func registerCells() {
        addCell(OAValueTableViewCell.reuseIdentifier)
    }
    
    func updateDataIfNeeded() {
        for (index, widget) in Self.widgets.enumerated() {
            guard let sectionIndex = tableData.index(ofSectionWithKey: Section.receivedData.key),
                  let row = tableData.row(at: IndexPath(row: index, section: sectionIndex)) else {
                continue
            }

            let oldDescr = row.descr

            let newDescr: String
            if let dataItem = OBDDataComputer.shared.widgets.first(where: { $0.type == widget }),
               let result = dataItem.computeValue(), !String(describing: result).isEmpty {
                let value = String(describing: result)
                let unit = (OAPluginsHelper.getEnabledPlugin(VehicleMetricsPlugin.self) as? VehicleMetricsPlugin)?
                    .getWidgetUnit(widget) ?? ""
                newDescr = unit.isEmpty ? value : "\(value) \(unit)"
            } else {
                newDescr = "N/A"
            }

            if row.descr != newDescr {
                row.descr = newDescr
                tableView.reloadRows(at: [IndexPath(row: index, section: sectionIndex)], with: .none)
            }
        }
    }

    
    override func generateData() {
        tableData.clearAllData()
        
        if DeviceHelper.shared.isPairedDevice(id: device.id) {
            if let vin = OBDDataComputer.shared.widgets.first(where: { $0.type == .vin }) {
                if let result = vin.computeValue() {
                    let stringValue = String(describing: result)
                    if !stringValue.isEmpty {
                        // Vehicle info
                        let vehicleInfoSection = tableData.createNewSection()
                        vehicleInfoSection.headerText = localizedString("obd_vehicle_info").uppercased()
                        vehicleInfoSection.footerText = localizedString("obd_vin_desc")
                        vehicleInfoSection.key = Section.vehicleInfo.key
                        
                        let vinRow = vehicleInfoSection.createNewRow()
                        vinRow.cellType = OAValueTableViewCell.reuseIdentifier
                        vinRow.key = "vin"
                        vinRow.title = localizedString("obd_vin")
                        vinRow.descr = device.isConnected ? stringValue : ""
                    }
                }
            }
            
            // Received Data
            let receivedDataSection = tableData.createNewSection()
            receivedDataSection.headerText = localizedString("external_device_details_received_data").uppercased()
            receivedDataSection.key = Section.receivedData.key
            
            for widget in Self.widgets {
                let row = receivedDataSection.createNewRow()
                row.cellType = OAValueTableViewCell.reuseIdentifier
                row.icon = widget.image
                row.key = "row"
                row.title = widget.getTitle()
                
                guard device.isConnected else {
                    row.descr = "N/A"
                    continue
                }
                
                guard let dataItem = OBDDataComputer.shared.widgets.first(where: { $0.type == widget }), let result = dataItem.computeValue() else {
                    row.descr = "N/A"
                    continue
                }
                
                let stringValue = String(describing: result)
                
                guard !stringValue.isEmpty else {
                    row.descr = "N/A"
                    continue
                }
                
                if stringValue == "N/A" || stringValue == "-" {
                    row.descr = stringValue
                } else {
                    let unit = (OAPluginsHelper.getEnabledPlugin(VehicleMetricsPlugin.self) as? VehicleMetricsPlugin)?
                        .getWidgetUnit(widget) ?? ""
                    
                    row.descr = unit.isEmpty ? stringValue : "\(stringValue) \(unit)"
                }
            }
            
            // Settings
            let settingsSection = tableData.createNewSection()
            settingsSection.headerText = localizedString("shared_string_settings").uppercased()
            settingsSection.key = Section.settings.key
            
            let nameRow = settingsSection.createNewRow()
            nameRow.cellType = OAValueTableViewCell.reuseIdentifier
            nameRow.key = "name_row"
            nameRow.title = localizedString("shared_string_name")
            nameRow.descr = device.deviceName
            
            let forgetSensorSection = tableData.createNewSection()
            forgetSensorSection.key = Section.forgetSensor.key
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
        if let section = Section(rawValue: section), section == .forgetSensor {
            return 34
        } else if !DeviceHelper.shared.isPairedDevice(id: device.id) {
            return .leastNonzeroMagnitude
        }
        return 56
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        DeviceHelper.shared.isPairedDevice(id: device.id) ? .leastNonzeroMagnitude : UITableView.automaticDimension
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == OAValueTableViewCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as? OAValueTableViewCell else {
                return nil
            }
            cell.descriptionVisibility(false)
            cell.separatorInset = .zero
            cell.valueLabel.text = item.descr
            cell.titleLabel.text = item.title
            let sectionKey = tableData.sectionData(for: UInt(indexPath.section)).key
            if sectionKey == Section.receivedData.key || sectionKey == Section.vehicleInfo.key {
                cell.leftIconVisibility(sectionKey == Section.receivedData.key)
                cell.imageView?.image = item.icon
                cell.selectionStyle = .none
                cell.accessoryType = .none
                cell.titleLabel.textColor = .textColorPrimary
            } else if sectionKey == Section.settings.key {
                cell.leftIconVisibility(false)
                cell.imageView?.image = nil
                cell.selectionStyle = .gray
                cell.accessoryType = .disclosureIndicator
                cell.titleLabel.textColor = .textColorPrimary
            } else if sectionKey == Section.forgetSensor.key {
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
    
    private func scrollToSearchSection() {
        for index in 0..<tableData.sectionCount() {
            let section = tableData.sectionData(for: index)
            if section.key == Section.settings.key {
                let indexPath = IndexPath(row: 0, section: Int(index))
                tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                break
            }
        }
    }
    
    private func configureHeader() {
        headerView.frame.size.height = 156
        headerView.frame.size.width = view.frame.width
        tableView.tableHeaderView = headerView
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
