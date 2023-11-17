//
//  BLESearchViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 12.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit
import CoreBluetooth
import SwiftyBluetooth

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
        if !hasFirstResult {
            startScan()
        }
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
    }
    
    override func generateData() {
        let discoveredDevices = BLEManager.shared.discoveredDevices
        if !discoveredDevices.isEmpty {
            tableData.clearAllData()
            let section = tableData.createNewSection()
            BLEManager.shared.discoveredDevices.forEach { _ in section.createNewRow() }
        }
    }
    
    override func getTitleForHeader(_ section: Int) -> String! {
        String(format: localizedString("bluetooth_found_title"), BLEManager.shared.discoveredDevices.count).uppercased()
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchDeviceTableViewCell.reuseIdentifier) as! SearchDeviceTableViewCell
        if BLEManager.shared.discoveredDevices.count > indexPath.row {
            cell.configure(item: BLEManager.shared.discoveredDevices[indexPath.row])
        }
        return cell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let controller = BLEDescriptionViewController()
        controller.device = BLEManager.shared.discoveredDevices[indexPath.row]
        navigationController?.pushViewController(controller, animated: true)
    }
    
    deinit {
        tableData.clearAllData()
        BLEManager.shared.stopScan()
        NotificationCenter.default.removeObserver(self)
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
            return
        }
        showSearchingView()
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
                                               queue: nil)
        { [weak self] notification in
            guard let self else { return }
            guard let state = notification.userInfo?["state"] as? CBManagerState else {
                return
            }
            if case .poweredOn = state {
                if !hasFirstResult {
                    startScan()
                }
                if !BLEManager.shared.discoveredDevices.isEmpty {
                    showDiscoveredDevices()
                }
            } else {
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
        tableView.reloadData()
    }
    
    // MARK: -  @IBActions
    
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
