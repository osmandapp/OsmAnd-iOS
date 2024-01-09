//
//  BLESearchViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 12.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit
import CoreBluetooth

final class BLESearchViewController: OABaseNavbarViewController {
    
    // MARK: - @IBOutlets
    
    @IBOutlet private weak var bluetoothTurnedOffView: UIView! {
        didSet {
            bluetoothTurnedOffView.isHidden = true
        }
    }
    @IBOutlet private weak var searchingView: UIView! {
        didSet {
            searchingView.isHidden = true
        }
    }
    @IBOutlet private weak var searchEmptyView: UIView! {
        didSet {
            searchEmptyView.isHidden = true
        }
    }
    @IBOutlet private weak var nothingFoundTitle: UILabel! {
        didSet {
            nothingFoundTitle.text = localizedString("ant_plus_nothing_found_text")
        }
    }
    @IBOutlet private weak var nothingFoundDescription: UILabel! {
        didSet {
            nothingFoundDescription.text = localizedString("ant_plus_nothing_found_description")
        }
    }
    @IBOutlet private weak var searchAgainButton: UIButton! {
        didSet {
            searchAgainButton.setTitle(localizedString("ble_search_again"), for: .normal)
        }
    }
    @IBOutlet private weak var searchingTitle: UILabel! {
        didSet {
            searchingTitle.text = localizedString("ant_plus_searching_text")
        }
    }
    @IBOutlet private weak var searchingDescription: UILabel! {
        didSet {
            searchingDescription.text = localizedString("ant_plus_searching_text_description")
        }
    }
    @IBOutlet private weak var openSettingButton: UIButton! {
        didSet {
            openSettingButton.setTitle(localizedString("ant_plus_open_settings"), for: .normal)
        }
    }
    @IBOutlet private weak var bluetoothOffTitle: UILabel! {
        didSet {
            bluetoothOffTitle.text = localizedString("ant_plus_bluetooth_off")
        }
    }
    @IBOutlet private weak var bluetoothOffDescription: UILabel! {
        didSet {
            bluetoothOffDescription.text = localizedString("ant_plus_bluetooth_off_description")
        }
    }
    
    private var hasFirstResult = false
    private var needRescan = false
    
    private var discoveredDevices: [Device] {
        let sortedDevices = BLEManager.shared.discoveredDevices.sorted { $0.isConnected && !$1.isConnected }
        return sortedDevices
    }
    
    // MARK: - Init
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initTableData()
    }
    
    // MARK: - Life cicle
    
    override func getTitle() -> String! {
        localizedString("ant_plus_searching")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 72
        tableView.backgroundColor = .clear
        view.backgroundColor = UIColor.viewBg
        tableView.sectionHeaderTopPadding = 26
        startScan()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        generateData()
        tableView.reloadData()
    }
    
    override func registerObservers() {
        detectBluetoothState()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceRSSIUpdated),
                                               name: .DeviceRSSIUpdated,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceDisconnected),
                                               name: .DeviceDisconnected,
                                               object: nil)
    }
    
    override func generateData() {
        tableData.clearAllData()
        if !discoveredDevices.isEmpty {
            let section = tableData.createNewSection()
            discoveredDevices.forEach { _ in section.createNewRow() }
        }
        tableView.reloadData()
    }
    
    override func getTitleForHeader(_ section: Int) -> String! {
        String(format: localizedString("bluetooth_found_title"), discoveredDevices.count).uppercased()
    }
    
    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        30
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchDeviceTableViewCell.reuseIdentifier) as! SearchDeviceTableViewCell
        // separators go edge to edge
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        cell.preservesSuperviewLayoutMargins = false
        
        if discoveredDevices.count > indexPath.row {
            cell.configure(item: discoveredDevices[indexPath.row])
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let controller = BLEDescriptionViewController()
        controller.device = discoveredDevices[indexPath.row]
        navigationController?.pushViewController(controller, animated: true)
    }
    
    deinit {
        BLEManager.shared.stopScan()
        BLEManager.shared.removeAllDiscoveredDevices()
    }
    
    private func showSearchingView() {
        searchingView.isHidden = false
        searchEmptyView.isHidden = true
        bluetoothTurnedOffView.isHidden = true
        tableView.isHidden = true
    }
    
    private func showEmptyView() {
        searchingView.isHidden = true
        searchEmptyView.isHidden = false
        bluetoothTurnedOffView.isHidden = true
        tableView.isHidden = true
    }
    
    private func showBluetoothTurnedOffView() {
        searchingView.isHidden = true
        searchEmptyView.isHidden = true
        bluetoothTurnedOffView.isHidden = false
        tableView.isHidden = true
    }
    
    private func showDiscoveredDevices() {
        searchingView.isHidden = true
        searchEmptyView.isHidden = true
        bluetoothTurnedOffView.isHidden = true
        tableView.isHidden = false
    }
    
    private func startScan() {
        guard !BLEManager.shared.isScaning else {
            print("startScan: isScaning")
            BLEManager.shared.stopScan()
            scanForPeripherals()
            return
        }
        scanForPeripherals()
    }
    
    private func scanForPeripherals() {
        showSearchingView()
        needRescan = false
        BLEManager.shared.scanForPeripherals(withServiceUUIDs: GattAttributes.SUPPORTED_SERVICES.map { $0.CBUUIDRepresentation }) { [weak self] in
            guard let self else { return }
            hasFirstResult = true
            showDiscoveredDevices()
            generateData()
            tableView.reloadData()
        } failureHandler: { [weak self] error in
            guard let self else { return }
            startScanResultWith(error: error)
        } scanStoppedHandler: { [weak self] hasResult in
            guard let self else { return }
            if hasResult {
                showDiscoveredDevices()
            } else {
                showEmptyView()
            }
        }
    }
    
    private func detectBluetoothState() {
        NotificationCenter.default.addObserver(forName: Central.CentralStateChange,
                                               object: Central.sharedInstance,
                                               queue: nil) { [weak self] notification in
            guard let self else { return }
            UserDefaults.standard.set(true, for: .wasAuthorizationRequestBluetooth)
            guard let state = notification.userInfo?["state"] as? CBManagerState else {
                return
            }
            if case .poweredOn = state {
                if !hasFirstResult || needRescan {
                    startScan()
                }
                if !discoveredDevices.isEmpty {
                    showDiscoveredDevices()
                }
            } else {
                if !discoveredDevices.isEmpty {
                    needRescan = true
                }
               showBluetoothTurnedOffView()
            }
        }
    }
    
    private func startScanResultWith(error: BLEManagerUnavailbleFailureReason) {
        switch error {
        case .unsupported:
            // "Your iOS device does not support Bluetooth."
            showScanErrorAlertWith(message: error.rawValue)
        case .unauthorized:
            // "Unauthorized to use Bluetooth."
            showBluetoothTurnedOffView()
        case .poweredOff:
            //  "Bluetooth is disabled, enable bluetooth and try again."
            showBluetoothTurnedOffView()
        case .unknown:
            // "Bluetooth is currently unavailable (unknown reason)."
            showScanErrorAlertWith(message: error.rawValue)
        case .scanningEndedUnexpectedly:
            showBluetoothTurnedOffView()
        }
    }
    
    private func showScanErrorAlertWith(message: String) {
        let alert = UIAlertController(title: localizedString("osm_failed_uploads"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func deviceRSSIUpdated() {
        guard view.window != nil else { return }
        tableView.reloadData()
    }
    
    @objc private func deviceDisconnected() {
        guard view.window != nil else { return }
        tableView.reloadData()
    }
    
    // MARK: - @IBActions
    
    @IBAction private func onOpenSettingsButtonPressed(_ sender: Any) {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsURL) else {
            return
        }
        UIApplication.shared.open(settingsURL)
    }
    
    @IBAction private func onSearchAgainButtonPressed(_ sender: Any) {
        startScan()
    }
}
