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
        view.backgroundColor = UIColor.viewBg
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
                                               selector: #selector(deviceDisconnected),
                                               name: .DeviceDisconnected,
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
        localizedString("vehicle_metrics_obd_ii")
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
        if DeviceHelper.shared.hasPairedDevices {
            configurePairedDevices()
        } else {
            configureNoPairedDevices()
        }
    }
    
    override func getTitleForHeader(_ section: Int) -> String? {
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
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
            if let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell {
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
        } else if item.cellType == SearchDeviceTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchDeviceTableViewCell.reuseIdentifier) as! SearchDeviceTableViewCell
            configureSeparator(cell: cell)

            if let key = item.key, let item = ConnectState(rawValue: key) {
                if let items = sectionsDevicesData[item], items.count > indexPath.row {
                    cell.configure(item: items[indexPath.row])
                }
            }
            return cell
        }
        
        return nil
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
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if let key = item.key {
            if let item = CellData(rawValue: key) {
                if case .learnMore = item {
                    guard let settingsURL = URL(string: docsVehicleMetricsURL),
                          UIApplication.shared.canOpenURL(settingsURL) else {
                        return
                    }
                    UIApplication.shared.open(settingsURL)
                }
            } else if let item = ConnectState(rawValue: key) {
                if let items = sectionsDevicesData[item], items.count > indexPath.row {
                    let controller = BLEDescriptionViewController()
                    controller.device = items[indexPath.row]
                    navigationController?.pushViewController(controller, animated: true)
                }
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
        pairNewSensorButton.isHidden = DeviceHelper.shared.hasPairedDevices
        if !DeviceHelper.shared.hasPairedDevices {
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
        NotificationCenter.default.removeObserver(self, name: Central.CentralStateChange, object: Central.sharedInstance)
        NotificationCenter.default.addObserver(forName: Central.CentralStateChange,
                                               object: Central.sharedInstance,
                                               queue: nil) { [weak self] _ in
            guard let self else { return }
            UserDefaults.standard.set(true, for: .wasAuthorizationRequestBluetooth)
            guard DeviceHelper.shared.hasPairedDevices else { return }
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
        let imageView = UIImageView(image: UIImage(named: "img_help_vehicle_metrics"))
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
        titleBLE.cellType = OASimpleTableViewCell.getIdentifier()
        titleBLE.key = CellData.title.rawValue

        let learnMoreBLE = section.createNewRow()
        learnMoreBLE.cellType = OASimpleTableViewCell.getIdentifier()
        learnMoreBLE.key = CellData.learnMore.rawValue
        learnMoreBLE.title = localizedString("learn_more_about_sensors_link")
    }
    
    private func getEmptyDescriptionAttributedString() -> NSAttributedString {
        let title = localizedString("connect_obd_instructions_title")
        let howTo = localizedString("obd_how_to_connect")
        let steps = String(format: localizedString("connect_obd_instructions_step"),  localizedString("external_device_status_connect")).replacingOccurrences(of: "\n\n", with: "\n")
        
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
        if let pairedDevices = DeviceHelper.shared.getSettingsForPairedDevices() {
            let connectedDevices = DeviceHelper.shared.connectedDevices
            
            if !connectedDevices.isEmpty {
                let connectedSection = tableData.createNewSection()
                connectedDevices.forEach { _ in
                    let row = connectedSection.createNewRow()
                    row.cellType = SearchDeviceTableViewCell.reuseIdentifier
                    row.key = ConnectState.connected.rawValue
                }
                sectionsDevicesData[.connected] = connectedDevices
            }
            let disconnectedDevices = DeviceHelper.shared.getDisconnectedDevices(for: pairedDevices)
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
            row.cellType = SearchDeviceTableViewCell.reuseIdentifier
            row.key = ConnectState.disconnected.rawValue
        }
        sectionsDevicesData[.disconnected] = disconnectedDevices
    }
    
    @objc private func pairNewSensor() {
        detectBluetoothState()
        let storyboard = UIStoryboard(name: "BLESearchViewController", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "BLESearchViewController") as? BLESearchViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc private func deviceDisconnected() {
        guard view.window != nil else { return }
        reloadData()
    }
    
    // MARK: - IBAction
    @IBAction private func onPairNewSensorButtonPressed(_ sender: Any) {
        pairNewSensor()
    }
}

// MARK: - UIContextMenuConfiguration
extension VehicleMetricsSensorsController {

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
        let controller = BLEDescriptionViewController()
        controller.device = device
        navigationController?.pushViewController(controller, animated: true)
    }
}

