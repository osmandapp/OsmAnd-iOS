//
//  VehicleMetricsSensorsController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 12.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import CoreBluetooth

final class VehicleMetricsSensorsController: OABaseNavbarViewController {
    
    private enum CellData: String {
        case title, learnMore
    }
    
    private enum ConnectState: String {
        case connected, disconnected
    }
    
    @IBOutlet private weak var pairNewSensorButton: UIButton! {
        didSet {
            pairNewSensorButton.setTitle(localizedString("external_device_status_connect"), for: .normal)
        }
    }
    
    private let headerEmptyView: UIView = UIView(frame: .zero)
    
    private var sectionsDevicesData = [ConnectState: [Device]]()
    private var centralStateObserver: NSObjectProtocol?
    
    private lazy var bluetoothDisableViewHeader: BluetoothDisableView = .fromNib()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initTableData()
    }

    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        view.backgroundColor = .viewBg
        tableView.contentInset.bottom = 64
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureStartState()
        reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureStartState()
    }
    
    override func registerObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDispatcherStart),
                                               name: .dispatcherStarted,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceDisconnected),
                                               name: .deviceDisconnected,
                                               object: nil)
        if UserDefaults.standard.bool(for: .wasAuthorizationRequestBluetooth) {
            detectBluetoothState()
        }
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func useCustomTableViewHeader() -> Bool {
        true
    }
    
    override func getTitle() -> String {
        localizedString("obd_plugin_name")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        let add = UIBarButtonItem(barButtonSystemItem: .add,
                                  target: self,
                                  action: #selector(onRightNavbarButtonPressed))
        add.tintColor = .iconColorActive
        return [add]
    }
    
    override func onRightNavbarButtonPressed() {
        pairNewSensor()
    }
    
    override func generateData() {
        tableData.clearAllData()

        if DeviceHelper.shared.hasPairedDevices(ofType: .OBD_VEHICLE_METRICS) {
            configurePairedDevices()
        } else {
            configureNoPairedDevices()
        }
    }
    
    override func getTitleForHeader(_ section: Int) -> String? {
        if DeviceHelper.shared.hasPairedDevices(ofType: .OBD_VEHICLE_METRICS) {
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
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell {
        let item = tableData.item(for: indexPath)
        if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            if let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as? OASimpleTableViewCell {
                cell.descriptionVisibility(false)
                cell.leftIconVisibility(false)
                cell.setCustomLeftSeparatorInset(true)
                cell.separatorInset = .zero
                cell.titleLabel.attributedText = nil
                cell.titleLabel.text = item.title
                if let key = item.key, let cellDataItem = CellData(rawValue: key) {
                    switch cellDataItem {
                    case .title:
                        cell.titleLabel.attributedText = getEmptyDescriptionAttributedString()
                        cell.titleLabel.textColor = .textColorPrimary
                        cell.selectionStyle = .none
                    case .learnMore:
                        cell.titleLabel.textColor = .textColorActive
                        cell.selectionStyle = .default
                    }
                }
                return cell
            }
        } else if item.cellType == SearchOBDDeviceTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchOBDDeviceTableViewCell.reuseIdentifier) as! SearchOBDDeviceTableViewCell
            configureSeparator(cell: cell)

            if let key = item.key, let item = ConnectState(rawValue: key) {
                if let items = sectionsDevicesData[item], items.count > indexPath.row {
                    cell.configure(item: items[indexPath.row])
                }
            }
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        DeviceHelper.shared.hasPairedDevices(ofType: .OBD_VEHICLE_METRICS) ? 30 : .leastNonzeroMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        guard let key = item.key else {
            return
        }
        if let item = CellData(rawValue: key) {
            if case .learnMore = item {
                guard let settingsURL = URL(string: docsVehicleMetricsURL) else {
                    return
                }
                let safariViewController = SFSafariViewController(url: settingsURL)
                safariViewController.preferredControlTintColor = .iconColorActive
                present(safariViewController, animated: true, completion: nil)
            }
        } else if let item = ConnectState(rawValue: key) {
            if let items = sectionsDevicesData[item], items.count > indexPath.row {
                let controller = VehicleMetricsDescriptionViewController()
                controller.device = items[indexPath.row]
                navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
    }
    
    private func configureSeparator(cell: UITableViewCell) {
        // separators go edge to edge
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        cell.preservesSuperviewLayoutMargins = false
    }
    
    private func configureStartState() {
        let hasPairedDevicesOnlyOBD = DeviceHelper.shared.hasPairedDevices(ofType: .OBD_VEHICLE_METRICS)
        pairNewSensorButton.isHidden = hasPairedDevicesOnlyOBD
        if !hasPairedDevicesOnlyOBD {
            tableView.sectionHeaderTopPadding = 0
            tableView.contentInset.top = 0
            tableView.contentInset.bottom = 64
            tableView.rowHeight = UITableView.automaticDimension
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
    
    private func detectBluetoothState() {
        if let centralStateObserver {
            NotificationCenter.default.removeObserver(centralStateObserver, name: Central.CentralStateChange, object: Central.sharedInstance)
        }

        centralStateObserver = NotificationCenter.default.addObserver(forName: Central.CentralStateChange,
                                                                      object: Central.sharedInstance,
                                                                      queue: nil) { [weak self] _ in
            guard let self else { return }
            UserDefaults.standard.set(true, for: .wasAuthorizationRequestBluetooth)

            guard DeviceHelper.shared.hasPairedDevices(ofType: .OBD_VEHICLE_METRICS) else { return }
            
            configureStartState()
            reloadData()
        }
    }
    
    private func reloadData() {
        generateData()
        tableView.reloadData()
    }
    
    private func configureEmptyHeader() {
        view.layoutIfNeeded()
        headerEmptyView.subviews.forEach { $0.removeFromSuperview() }

        let imageView = UIImageView(image: .imgHelpVehicleMetrics)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        headerEmptyView.addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: headerEmptyView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: headerEmptyView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: headerEmptyView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: headerEmptyView.bottomAnchor)
        ])
        
        headerEmptyView.frame.size.height = 201
        headerEmptyView.frame.size.width = view.frame.width
        headerEmptyView.backgroundColor = UIColor.groupBg
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
        titleBLE.cellType = OASimpleTableViewCell.reuseIdentifier
        titleBLE.key = CellData.title.rawValue

        let learnMoreBLE = section.createNewRow()
        learnMoreBLE.cellType = OASimpleTableViewCell.reuseIdentifier
        learnMoreBLE.key = CellData.learnMore.rawValue
        learnMoreBLE.title = localizedString("learn_more_about_sensors_link")
    }
    
    private func getEmptyDescriptionAttributedString() -> NSAttributedString {
        let title = localizedString("connect_obd_instructions_title")
        let howTo = localizedString("obd_how_to_connect")
        let steps = String(format: localizedString("connect_obd_instructions_step"), localizedString("external_device_status_connect")).replacingOccurrences(of: "\n\n", with: "\n")
        
        let fullText = "\(title)\n\n\(howTo)\n\(steps)"
        let fullAttributedText = NSMutableAttributedString(string: fullText)
        
        if let boldFont = UIFont.scaledBoldSystemFont(ofSize: 17) {
            let howToRange = (fullText as NSString).range(of: howTo)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = 12
            
            fullAttributedText.addAttributes([
                .font: boldFont,
                .paragraphStyle: paragraphStyle
            ], range: howToRange)
        }
        
        return fullAttributedText
    }
    
    private func configurePairedDevices() {
        sectionsDevicesData.removeAll()

        if let pairedDevices = DeviceHelper.shared.getSettingsForPairedDevices(matching: .OBD_VEHICLE_METRICS) {
            let connectedDevices = DeviceHelper.shared.connectedDevices(ofType: .OBD_VEHICLE_METRICS)
            
            if !connectedDevices.isEmpty {
                let connectedSection = tableData.createNewSection()
                connectedDevices.forEach { _ in
                    let row = connectedSection.createNewRow()
                    row.cellType = SearchOBDDeviceTableViewCell.reuseIdentifier
                    row.key = ConnectState.connected.rawValue
                }
                sectionsDevicesData[.connected] = connectedDevices
            }
            let disconnectedDevices = DeviceHelper.shared.getDisconnectedDevices(for: pairedDevices).filter { $0.deviceType == .OBD_VEHICLE_METRICS }
            if !disconnectedDevices.isEmpty {
                createDisconnectedDevicesSection(disconnectedDevices: disconnectedDevices)
            }
            tableView.reloadData()
        }
    }
    
    private func createDisconnectedDevicesSection(disconnectedDevices: [Device]) {
        let disconnectedSection = tableData.createNewSection()
        disconnectedDevices.forEach { _ in
            let row = disconnectedSection.createNewRow()
            row.cellType = SearchOBDDeviceTableViewCell.reuseIdentifier
            row.key = ConnectState.disconnected.rawValue
        }
        sectionsDevicesData[.disconnected] = disconnectedDevices
    }
    
    @objc private func pairNewSensor() {
        detectBluetoothState()
        let storyboard = UIStoryboard(name: "VehicleMetricsSearchViewController", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "VehicleMetricsSearchViewController") as? VehicleMetricsSearchViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc private func handleDispatcherStart() {
        guard view.window != nil else { return }
        self.reloadData()
    }
    
    @objc private func deviceDisconnected() {
        guard view.window != nil else { return }
        reloadData()
    }
    
    // MARK: - IBAction
    @IBAction private func onPairNewSensorButtonPressed(_ sender: Any) {
        pairNewSensor()
    }
    
    deinit {
        if let observer = centralStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - UIContextMenuConfiguration

extension VehicleMetricsSensorsController {
    private func getConnectionStateAction(for device: Device) -> UIAction {
        let isConnected = device.isConnected

        let titleKey = isConnected ? "external_device_status_disconnect" : "external_device_status_connect"
        let image: UIImage = isConnected ? .icCustomObd2ConnectorDisable : .icCustomObd2Connector
        let actionTitle = localizedString(titleKey)

        let action = UIAction(title: actionTitle, image: image) { _ in
            if isConnected {
                device.disconnect(completion: { _ in })
            } else {
                DeviceHelper.shared.updateConnected(devices: [device])
            }
        }
        return action
    }
    
    override func tableView(_ tableView: UITableView,
                            contextMenuConfigurationForRowAt indexPath: IndexPath,
                            point: CGPoint) -> UIContextMenuConfiguration? {
        guard let device = getDeviceFor(indexPath: indexPath) else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            self?.buildContextMenu(for: device)
        }
    }

    private func buildContextMenu(for device: Device) -> UIMenu {
        let connectionAction = getConnectionStateAction(for: device)
        let settings = UIAction(title: localizedString("shared_string_settings"), image: .icCustomSettingsOutlined) { [weak self] _ in
            self?.showDescriptionViewController(device: device, startBehavior: .scrollToSearch)
        }
        let rename = UIAction(title: localizedString("shared_string_rename"), image: .icCustomEdit) { [weak self] _ in
            self?.showRenameViewController(device: device)
        }
        let forget = UIAction(title: localizedString("external_device_menu_forget"),
                              image: .icCustomObd2ConnectorDisconnect,
                              attributes: .destructive) { [weak self] _ in
            self?.showForgetSensorActionSheet(device: device)
        }
        
        return UIMenu.composedMenu(from: [
            [connectionAction],
            [settings, rename],
            [forget]
        ])
    }
    
    private func getDeviceFor(indexPath: IndexPath) -> Device? {
        let item = tableData.item(for: indexPath)
        if let key = item.key, let item = ConnectState(rawValue: key) {
            if let items = sectionsDevicesData[item], items.count > indexPath.row {
                return items[indexPath.row]
            }
        }
        return nil
    }
    
    private func showForgetSensorActionSheet(device: Device) {
        let alert = UIAlertController(title: device.deviceName, message: localizedString("external_device_forget_sensor_description"), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: localizedString("external_device_forget_sensor"), style: .destructive, handler: {  _ in
            DeviceHelper.shared.setDevicePaired(device: device, isPaired: false)
            self.configureStartState()
            self.reloadData()
        }))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        alert.popoverPresentationController?.sourceView = view
        present(alert, animated: true)
    }
    
    private func showRenameViewController(device: Device) {
        let nameVC = BLEChangeDeviceNameViewController()
        nameVC.device = device
        nameVC.onSaveAction = { [weak self] in
            self?.reloadData()
        }
        navigationController?.present(UINavigationController(rootViewController: nameVC), animated: true)
    }
    
    private func showDescriptionViewController(device: Device) {
        let controller = VehicleMetricsDescriptionViewController()
        controller.device = device
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func showDescriptionViewController(device: Device, startBehavior: VehicleMetricsDescriptionViewController.TableViewStartBehavior) {
        let controller = VehicleMetricsDescriptionViewController()
        controller.device = device
        controller.startBehavior = .scrollToSearch
        navigationController?.pushViewController(controller, animated: true)
    }
}
