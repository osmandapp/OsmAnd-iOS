//
//  VehicleMetricsDescriptionViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 19.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Combine

public enum OBDServiceError: Error {
    //case noAdapterFound
 //   case notConnectedToVehicle
//    case adapterConnectionFailed(underlyingError: Error)
//    case scanFailed(underlyingError: Error)
 //   case clearFailed(underlyingError: Error)
    case commandFailed(command: String, error: Error)
}

final class VehicleMetricsDescriptionViewController: OABaseNavbarViewController {
    
    private enum Section: Int {
        case information, receivedData, settings, forgetSensor
    }
    
    private var info: OBDInfo?
    
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
    
    private lazy var headerView: DescriptionDeviceHeader = {
        Bundle.main.loadNibNamed("DescriptionDeviceHeader", owner: self, options: nil)?[0] as! DescriptionDeviceHeader
    }()
    
        
    private var timer: Timer?
    private var isUpdating = false
    
    func startContinuousUpdates(pids: [OBDCommand],
                                unit: MeasurementUnit = .metric,
                                interval: TimeInterval = 0.3) {
        guard !isUpdating else { return }
        isUpdating = true
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.updatePIDs(pids, unit: unit)
            }
        }
    }
    
    private func updatePIDs(_ pids: [OBDCommand], unit: MeasurementUnit) async {
        do {
            let results = try await requestPIDs(pids, unit: unit)
            updateResults(measurements: results)
        } catch {
            print("Ошибка при получении PID: \(error)")
        }
    }
    
    func updateResults(measurements: [OBDCommand: MeasurementResult]) {
        for (pid, measurement) in measurements {
            print("command: \(pid.properties.command) | description: \(pid.properties.description) ) | value:  \(measurement.value)")
        }
    }
    
    func stopContinuousUpdates() {
        guard isUpdating else { return }

        timer?.invalidate()
        timer = nil
        isUpdating = false
    }
    
    func requestPIDs(_ commands: [OBDCommand], unit: MeasurementUnit) async throws -> [OBDCommand: MeasurementResult] {
        let response = try await sendCommandInternal("01" + commands.compactMap { $0.properties.command.dropFirst(2) }.joined(), retries: 10)

        guard let responseData = try DeviceHelper.shared.elm327Adapter.canProtocol?.parse(response).first?.data else { return [:] }

        var batchedResponse = BatchedResponse(response: responseData, unit)

        let results: [OBDCommand: MeasurementResult] = commands.reduce(into: [:]) { result, command in
            let measurement = batchedResponse.extractValue(command)
            result[command] = measurement
        }

        return results
    }
    
    func sendCommandInternal(_ message: String, retries: Int) async throws -> [String] {
        do {
            return try await DeviceHelper.shared.elm327Adapter.sendCommand(message, retries: retries)
        } catch {
            throw OBDServiceError.commandFailed(command: message, error: error)
        }
    }
    
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
        headerView.onUpdateOBDInfoAction = { [weak self] result in
            guard let self else { return }
            info = result
            // Engine speed - RPM (Revolutions Per Minute)
            //   case .rpm
            
            // Intake temperature
            //  case .intakeTemp: return """
            
            // Vehicle speed
            // case .speed: return CommandProperties("010D", "Vehicle Speed", 2, .uas(0x09), true, maxValue: 280)
            
            // Ambient temperature
            // ambientAirTemp
            
            // Coolant temperature
            // case .coolantTemp:
            
            //Engine Oil Temperature
            // .engineOilTemp
            
           // Calculated Engine Load
           // case .engineLoad: return CommandProperties("0104", "Calculated Engine Load", 2, .percent, true)
            
           // Fuel Pressure
           // case .fuelPressure: return CommandProperties("010A", "Fuel Pressure", 2, .fuelPressure, true, maxValue: 765)
            
          // Throttle Position
          // case .throttlePos: return CommandProperties("0111", "Throttle Position", 2, .percent, true)
            
          // Battery voltage
          // case .controlModuleVoltage: return CommandProperties("0142", "Control module voltage", 4, .uas(0x0B), true)
            
          // Fuel type
          // case .fuelType: return CommandProperties("0151", "Fuel Type", 2, .fuelType)
            
          // Fuel consumption
          // case .fuelRate: return CommandProperties("015E", "Engine fuel rate", 4, .fuelRate, true
          // OBD_FUEL_CONSUMPTION_RATE_COMMAND(0x01, 0x5E, 2, OBDUtils::parseFuelConsumptionRateResponse, "vm_fcons"),
            
         // Remaining fuel
         // case .fuelLevel: return CommandProperties("012F", "Fuel Tank Level Input", 4, .percent, true)
         // OBD_FUEL_LEVEL_COMMAND(0x01, 0x2F, 1, OBDUtils::parsePercentResponse, "vm_fuel");
   
        // NOTE: limit 6 commands after receive response:  ["NO DATA"]
            // TODO: use supported pids
            startContinuousUpdates(pids: [.mode1(.rpm),
                                          .mode1(.speed),
                                          .mode1(.intakeTemp),
                                          .mode1(.ambientAirTemp),
                                          .mode1(.coolantTemp),
                                          .mode1(.engineOilTemp),
// >>>>>>>
//                                          .mode1(.engineLoad),
//                                          .mode1(.fuelPressure),
//                                          .mode1(.throttlePos),
//                                          .mode1(.controlModuleVoltage),
//                                          .mode1(.fuelType),
//                                          .mode1(.fuelRate),
//                                          .mode1(.fuelLevel)
                                          ])
            generateData()
            tableView.reloadData()
        }
        tableView.tableHeaderView = headerView
        registerObservers()
    }
    
    override func setupTableHeaderView() {
        configureHeader()
    }
    
    override func registerCells() {
        addCell(OAValueTableViewCell.reuseIdentifier)
    }
    
    private func configureHeader() {
        headerView.frame.size.height = 156
        headerView.frame.size.width = view.frame.width
        tableView.tableHeaderView = headerView
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        if DeviceHelper.shared.isPairedDevice(id: device.id) {
            if let info, let vin = info.vin, !vin.isEmpty {
                // Vehicle info
                let vehicleInfoSection = tableData.createNewSection()
                vehicleInfoSection.headerText = localizedString("obd_vehicle_info").uppercased()
                vehicleInfoSection.footerText = localizedString("obd_vin_desc")
                vehicleInfoSection.key = "vehicle_info"
                
                let vinRow = vehicleInfoSection.createNewRow()
                vinRow.cellType = OAValueTableViewCell.reuseIdentifier
                vinRow.key = "vin"
                vinRow.title = localizedString("obd_vin")
                vinRow.descr = vin
            }
            
            // Received Data
            if let receivedData = device.getDataFields, !receivedData.isEmpty {
                let receivedDataSection = tableData.createNewSection()
                receivedDataSection.headerText = localizedString("external_device_details_received_data").uppercased()
                receivedDataSection.key = "receivedData"
                for array in receivedData {
                    if let dic = array.first {
                        let row = receivedDataSection.createNewRow()
                        row.cellType = OAValueTableViewCell.reuseIdentifier
                        row.key = "row"
                        row.title = dic.key
                        row.descr = dic.value != "0" ? dic.value : "-"
                    }
                }
            }
            // Settings
            let settingsSection = tableData.createNewSection()
            settingsSection.headerText = localizedString("shared_string_settings").uppercased()
            settingsSection.key = "settings"
            
            let nameRow = settingsSection.createNewRow()
            nameRow.cellType = OAValueTableViewCell.reuseIdentifier
            nameRow.key = "name_row"
            nameRow.title = localizedString("shared_string_name")
            nameRow.descr = device?.deviceName ?? ""
            
//            if let settingsDataDict = device.getSettingsFields, !settingsDataDict.isEmpty {
//                for (key, value) in settingsDataDict {
//                    let settingRow = settingsSection.createNewRow()
//                    settingRow.cellType = OAValueTableViewCell.reuseIdentifier
//                    settingRow.key = key
////                    if let floatValue = value as? Float {
////                        settingRow.descr = String(format: "%.0f", floatValue) + " " + localizedString("shared_string_millimeters_short")
////                    }
//                }
//            }
            
            let forgetSensorSection = tableData.createNewSection()
            forgetSensorSection.key = "forgetSensor"
            let forgetSensorRow = forgetSensorSection.createNewRow()
            forgetSensorRow.cellType = OAValueTableViewCell.reuseIdentifier
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
            cell.leftIconVisibility(false)
            cell.separatorInset = .zero
            cell.valueLabel.text = item.descr
            cell.titleLabel.text = item.title
            let sectionKey = tableData.sectionData(for: UInt(indexPath.section)).key
            if sectionKey == "information" || sectionKey == "receivedData" {
                cell.selectionStyle = .none
                cell.accessoryType = .none
                cell.titleLabel.textColor = .textColorPrimary
            } else if sectionKey == "settings" {
                cell.selectionStyle = .gray
                cell.accessoryType = .disclosureIndicator
                cell.titleLabel.textColor = .textColorPrimary
            } else if sectionKey == "forgetSensor" {
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
    
    // TODO: deviceRSSIUpdated ?
    override func registerObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceRSSIUpdated),
                                               name: .DeviceRSSIUpdated,
                                               object: nil)
    }
    
    @objc private func deviceRSSIUpdated() {
        headerView.updateRSSI(with: device.rssi)
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
