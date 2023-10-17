//
//  BLEDescriptionViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.10.2023.
//

import UIKit

final class BLEDescriptionViewController: OABaseNavbarViewController {
    
    private enum Section: Int {
        case information, receivedData, settings, forgetSensor
    }
    
    var device: Device! {
        didSet {
            device.didChangeCharacteristic = { [weak self] in
                guard let self else { return }
                generateData()
                tableView.reloadData()
            }
        }
    }
    
    private lazy var headerView: DescriptionDeviceHeader = {
        Bundle.main.loadNibNamed("DescriptionDeviceHeader", owner: self, options: nil)?[0] as! DescriptionDeviceHeader
    }()
    
    // MARK: - Init
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initTableData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 48
        tableView.tableFooterView = nil
        configureHeader()
        headerView.configure(item: device)
        tableView.tableHeaderView = headerView
        registerObservers()
    }
    
    override func setupTableHeaderView() {
        configureHeader()
    }
    
    private func configureHeader() {
        headerView.frame.size.height = 156
        headerView.frame.size.width = view.frame.width
        tableView.tableHeaderView = headerView
    }
    
    override func generateData() {
        tableData.clearAllData()
        // Information
        if let sensor = device.sensors.first(where: { $0 is BLEBatterySensor }) as? BLEBatterySensor {
            let infoSection = tableData.createNewSection()
            infoSection.headerText = "Information".uppercased()
            let batteryRow = infoSection.createNewRow()
            batteryRow.cellType = OAValueTableViewCell.getIdentifier()
            batteryRow.key = "battery_row"
            batteryRow.title = "Battery"
            batteryRow.descr = sensor.lastBatteryData.batteryLevel != -1 ? String(sensor.lastBatteryData.batteryLevel) + "%" : "-"
        }
        // Received Data
        if let receivedData = device.getDataFields {
            let receivedDataSection = tableData.createNewSection()
            receivedDataSection.headerText = "Received Data".uppercased()
            for (key, value) in receivedData {
                let row = receivedDataSection.createNewRow()
                row.cellType = OAValueTableViewCell.getIdentifier()
                row.key = "row"
                row.title = key
                row.descr = value != "0" ? value : "-"
            }
        }
        // Settings
        let settingsSection = tableData.createNewSection()
        settingsSection.headerText = "Settings".uppercased()
        let nameRow = settingsSection.createNewRow()
        nameRow.cellType = OAValueTableViewCell.getIdentifier()
        nameRow.key = "name_row"
        nameRow.title = "Name"
        nameRow.descr = device?.deviceName ?? ""
        
        if let settingsData = device.getSettingsFields {
            
        }
        
        let forgetSensorSection = tableData.createNewSection()
        let forgetSensorRow = forgetSensorSection.createNewRow()
        forgetSensorRow.cellType = OAValueTableViewCell.getIdentifier()
        forgetSensorRow.key = "forget_sensor_row"
        forgetSensorRow.title = "Forget sensor"
    }
    
    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        if let section = Section(rawValue: section), section == .forgetSensor {
            return 10
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData!.item(for: indexPath)
        let isForgetSensorCell = item.key == "forget_sensor_row"
        if item.cellType == OAValueTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.getIdentifier()) as? OAValueTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OAValueTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OAValueTableViewCell
                cell?.descriptionVisibility(false)
                cell?.leftIconVisibility(false)
            }
            if let cell {
                if indexPath.section <= 1 {
                    cell.selectionStyle = .none
                    cell.accessoryType = .none
                } else {
                    if isForgetSensorCell {
                        cell.accessoryType = .none
                    } else {
                        cell.accessoryType = .disclosureIndicator
                    }
                }
                cell.separatorInset = .zero
                cell.valueLabel.text = item.descr
                cell.titleLabel.text = item.title
                if isForgetSensorCell {
                    cell.titleLabel.textColor = UIColor.buttonBgColorDisruptive
                }
            }
            return cell
        }
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if item.key == "forget_sensor_row" {
            showForgetSensorActionSheet()
        } else if item.key == "name_row" {
            let nameVC = BLEChangeDeviceNameViewController()
            nameVC.device = device
            nameVC.onSaveAction = { [weak self] in
                guard let self else { return }
                generateData()
                tableView.reloadData()
            }
            navigationController?.present(UINavigationController(rootViewController: nameVC), animated: true)
        }
    }
    
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

extension BLEDescriptionViewController {
    private func showForgetSensorActionSheet() {
        let alert = UIAlertController(title: device.deviceName, message: "Sensor will be removed from the list. You will be able to pair this sensor again at any time.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Forget sensor", style: .destructive , handler: { _ in
            print("Forget sensor")
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: { _ in
            print("Cancel")
        }))
        alert.popoverPresentationController?.sourceView = view
        present(alert, animated: true)
    }
}
