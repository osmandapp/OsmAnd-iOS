//
//  BLEExternalSensorsViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 13.10.2023.
//

import UIKit
import SwiftyBluetooth
import CoreBluetooth

final class BLEExternalSensorsViewController: OABaseNavbarViewController {
    
    private enum ExternalSensorsCellData: String {
        case title, learnMore
    }
    
    private enum ExternalSensorsConnectState: String {
        case connected, disconnected
    }
    
    @IBOutlet private weak var pairNewSensorButton: UIButton! {
        didSet {
            pairNewSensorButton.setTitle(localizedString("ant_plus_pair_new_sensor"), for: .normal)
        }
    }
    
    private let headerEmptyView: UIView = UIView(frame: .zero)
    
    private var sectionsDevicesData = [ExternalSensorsConnectState: [Device]]()
    
    private lazy var bluetoothDisableViewHeader: BluetoothDisableView = .fromNib()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initTableData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        view.backgroundColor = UIColor.viewBgColor
        
        tableView.contentInset.bottom = 64
    }
    
    override func useCastomTableViewHeader() -> Bool {
        true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureStartState()
        generateData()
        tableView.reloadData()
    }
    
    override func registerObservers() {
        detectBluetoothState()
    }
    
    override func getTitle() -> String! {
        localizedString("external_sensors_plugin_name")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        let add = UIBarButtonItem(barButtonSystemItem: .add,
                                  target: self,
                                  action: #selector(onRightNavbarButtonPressed))
        add.tintColor = UIColor.buttonBgColorPrimary
        return [add]
    }
    
    override func onRightNavbarButtonPressed() {
        pairNewSensor()
    }
    
    override func generateData() {
        tableData.clearAllData()
        if DeviceHelper.shared.hasPairedDevices {
            configurePairedDevices()
        } else {
            configureNoPairedDevices()
        }
    }
    
    override func getTitleForHeader(_ section: Int) -> String! {
        if DeviceHelper.shared.hasPairedDevices {
            switch section {
            case 0:
                if let connected = sectionsDevicesData[.connected], !connected.isEmpty {
                    return localizedString("external_device_status_connected").uppercased()
                } else if let disconnected = sectionsDevicesData[.disconnected], !disconnected.isEmpty {
                    return localizedString("external_device_status_disconnected").uppercased()
                }
            case 1:
                if let disconnected = sectionsDevicesData[.disconnected], !disconnected.isEmpty {
                    return localizedString("external_device_status_disconnected").uppercased()
                }
            default: break
            }
        }
        return nil
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASimpleTableViewCell
                cell?.descriptionVisibility(false)
                cell?.leftIconVisibility(false)
            }
            if let cell {
                cell.titleLabel.text = item.title
                if let key = item.key, let item = ExternalSensorsCellData(rawValue: key) {
                    switch item {
                    case .title:
                        cell.titleLabel.textColor = UIColor.textColorPrimary
                        cell.selectionStyle = .none
                    case .learnMore:
                        cell.titleLabel.textColor = UIColor.buttonBgColorPrimary
                        cell.selectionStyle = .default
                    }
                }
            }
            outCell = cell
        } else if item.cellType == SearchDeviceTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchDeviceTableViewCell.reuseIdentifier) as! SearchDeviceTableViewCell
            if let key = item.key, let item = ExternalSensorsConnectState(rawValue: key) {
                if let items = sectionsDevicesData[item], items.count > indexPath.row {
                    cell.configure(item: items[indexPath.row])
                }
            }
            return cell
        }
        
        return outCell
    }
    
    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        if DeviceHelper.shared.hasPairedDevices {
            return 30
        }
        return .leastNonzeroMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if let key = item.key {
            if let item = ExternalSensorsCellData(rawValue: key) {
                if case .learnMore = item {
                    guard let settingsURL = URL(string: docs_external_sensors),
                          UIApplication.shared.canOpenURL(settingsURL) else {
                        return
                    }
                    UIApplication.shared.open(settingsURL)
                }
            } else if let item = ExternalSensorsConnectState(rawValue: key) {
                if let items = sectionsDevicesData[item], items.count > indexPath.row {
                    let controller = BLEDescriptionViewController()
                    controller.device = items[indexPath.row]
                    navigationController?.pushViewController(controller, animated: true)
                }
            }
        }
    }
    
    private func configureStartState() {
        pairNewSensorButton.isHidden = DeviceHelper.shared.hasPairedDevices
        if !DeviceHelper.shared.hasPairedDevices {
            tableView.sectionHeaderTopPadding = 0
            tableView.contentInset.top = 0
            tableView.contentInset.bottom = 64
            configureEmptyHeader()
        } else {
            tableView.rowHeight = 72
            tableView.sectionHeaderTopPadding = 26
            tableView.contentInset.bottom = 0
            if BLEManager.shared.getBluetoothState() != .poweredOn {
                tableView.contentInset.top = 34
                configureBluetoothDisableViewHeader()
            } else {
                tableView.contentInset.top = 0
                tableView.tableHeaderView = nil
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureStartState()
    }
    
    private func detectBluetoothState() {
        NotificationCenter.default.addObserver(forName: Central.CentralStateChange,
                                               object: Central.sharedInstance,
                                               queue: nil)
        { [weak self] _ in
            guard let self else { return }
            guard DeviceHelper.shared.hasPairedDevices else { return }
            configureStartState()
            generateData()
            tableView.reloadData()
        }
    }
    
    private func configureEmptyHeader() {
        headerEmptyView.subviews.forEach { $0.removeFromSuperview() }
        let imageView = UIImageView(image: UIImage(named: "img_help_sensors_day"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        headerEmptyView.addSubview(imageView)
        headerEmptyView.frame.size.height = 201
        headerEmptyView.frame.size.width = view.frame.width
        imageView.frame = headerEmptyView.frame
        tableView.tableHeaderView = headerEmptyView
    }
    
    private func configureBluetoothDisableViewHeader() {
        bluetoothDisableViewHeader.frame.size.height = 157
        bluetoothDisableViewHeader.frame.size.width = view.frame.width
        tableView.tableHeaderView = bluetoothDisableViewHeader
    }
    
    private func configureNoPairedDevices() {
        let section = tableData.createNewSection()
        let titleBLE = section.createNewRow()
        titleBLE.cellType = OASimpleTableViewCell.getIdentifier()
        titleBLE.key = ExternalSensorsCellData.title.rawValue
        titleBLE.title = localizedString("ant_plus_pair_bluetooth_prompt")
        
        let learnMoreBLE = section.createNewRow()
        learnMoreBLE.cellType = OASimpleTableViewCell.getIdentifier()
        learnMoreBLE.key = ExternalSensorsCellData.learnMore.rawValue
        learnMoreBLE.title = localizedString("learn_more_about_sensors_link")
    }
    
    private func configurePairedDevices() {
        sectionsDevicesData.removeAll()
        if let pairedDevices = DeviceHelper.shared.getSettingsForPairedDevices() {
            let peripherals = SwiftyBluetooth.retrievePeripherals(withUUIDs: pairedDevices.map { UUID(uuidString: $0.deviceId)!})
            let connectedPeripherals = peripherals.filter { $0.state == .connected }
            DeviceHelper.shared.updatePeripheralsForConnectedDevices(peripherals: connectedPeripherals)
            
            let disconnectedPeripherals = peripherals.filter { $0.state != .connected }
            var connectedDevices = DeviceHelper.shared.connectedDevices
            
            if !connectedDevices.isEmpty {
                let connectedSection = tableData.createNewSection()
                connectedDevices.forEach { _ in
                    let row = connectedSection.createNewRow()
                    row.cellType = SearchDeviceTableViewCell.reuseIdentifier
                    row.key = ExternalSensorsConnectState.connected.rawValue
                }
                sectionsDevicesData[.connected] = connectedDevices
            }
            if !disconnectedPeripherals.isEmpty {
                createDesconnectedDevicesSection(disconnectedPeripherals: disconnectedPeripherals, pairedDevices: pairedDevices)
            }
            tableView.reloadData()
        }
    }
    
    private func createDesconnectedDevicesSection(disconnectedPeripherals: [Peripheral], pairedDevices: [DeviceSettings]) {
        let disconnectedSection = tableData.createNewSection()
        disconnectedPeripherals.forEach { _ in
            let row = disconnectedSection.createNewRow()
            row.cellType = SearchDeviceTableViewCell.reuseIdentifier
            row.key = ExternalSensorsConnectState.disconnected.rawValue
        }
        sectionsDevicesData[.disconnected] = DeviceHelper.shared.getDevicesFrom(peripherals: disconnectedPeripherals,
                                                                                pairedDevices: pairedDevices)
    }
    
    @objc private func pairNewSensor() {
        let storyboard = UIStoryboard(name: "BLESearchViewController", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "BLESearchViewController") as? BLESearchViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - IBAction
    @IBAction private func onPairNewSensorButtonPressed(_ sender: Any) {
        pairNewSensor()
    }
}

// MARK: - UIContextMenuConfiguration
extension BLEExternalSensorsViewController {

    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let device = getDeviceFor(indexPath: indexPath) else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self else { return nil }
            
            let info = UIAction(title: localizedString("info_button"), image: UIImage(systemName: "info.circle")) { _ in
                self.showDescriptionViewController(device: device)
            }
            let rename = UIAction(title: localizedString("shared_string_rename"), image: UIImage(systemName: "square.and.pencil")) { _ in
                self.showRenameViewController(device: device)
            }
            let forget = UIAction(title: localizedString("external_device_menu_forget"), image: UIImage(systemName: "xmark.circle")) { _ in
                self.showForgetSensorActionSheet(device: device)
            }
            return UIMenu(title: "", options: .displayInline, children: [info, rename, forget])
        }
    }
    
    private func getDeviceFor(indexPath: IndexPath) -> Device? {
        let item = tableData.item(for: indexPath)
        if let key = item.key, let item = ExternalSensorsConnectState(rawValue: key) {
            if let items = sectionsDevicesData[item], items.count > indexPath.row {
                return items[indexPath.row]
            }
        }
        return nil
    }
    
    private func showForgetSensorActionSheet(device: Device) {
        let alert = UIAlertController(title: device.deviceName, message: localizedString("external_device_forget_sensor_description"), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: localizedString("external_device_forget_sensor"), style: .destructive , handler: {  _ in
            DeviceHelper.shared.setDevicePaired(device: device, isPaired: false)
            self.configureStartState()
            self.generateData()
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        alert.popoverPresentationController?.sourceView = view
        present(alert, animated: true)
    }
    
    private func showRenameViewController(device: Device) {
        let nameVC = BLEChangeDeviceNameViewController()
        nameVC.device = device
        nameVC.onSaveAction = { [weak self] in
            guard let self else { return }
            generateData()
            tableView.reloadData()
        }
        navigationController?.present(UINavigationController(rootViewController: nameVC), animated: true)
    }
    
    private func showDescriptionViewController(device: Device) {
        let controller = BLEDescriptionViewController()
        controller.device = device
        navigationController?.pushViewController(controller, animated: true)
    }
}
