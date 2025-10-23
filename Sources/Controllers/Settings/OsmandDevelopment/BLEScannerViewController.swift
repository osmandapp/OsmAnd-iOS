//
//  BLEScannerViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 22.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

private struct DiscoveredDevice {
    let name: String
    let identifier: String
    let rssi: Int
}

final class BLEScannerViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var devices: [DiscoveredDevice] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = localizedString("ble_scanner")
        view.backgroundColor = .systemBackground
        navigationController?.setDefaultNavigationBarAppearance()
        configureNavigationLeftBarButtonItemButtons()
        setupTableView()
        startScan()
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DeviceCell")
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func log(_ message: String) {
        NSLog("[\(String(describing: type(of: self)))] -> \(message)")
    }
    
    private func startScan() {
        devices.removeAll()
        tableView.reloadData()
        
        log("Starting scan...")
        SwiftyBluetooth.scanForPeripherals(withServiceUUIDs: nil, timeoutAfter: 15) { [weak self] scanResult in
            guard let self else { return }
            
            switch scanResult {
            case .scanStarted:
                log("Scan Started")
                
            case let .scanResult(peripheral, advertisementData, RSSI):
                let rssi = RSSI ?? -1
                let id = peripheral.identifier.uuidString
                let deviceName = advertisementData["kCBAdvDataLocalName"] as? String ?? peripheral.name ?? "Unknown"
                log("Peripheral Identifier: \(id), RSSI: \(rssi)")
                log("Peripheral Name: \(peripheral.name ?? "nil")")
                log("Device Name: \(deviceName)")
                
                if !advertisementData.isEmpty {
                    log("Advertisement Data ▼")
                    for (key, value) in advertisementData {
                        log("• \(key): \(value)")
                    }
                    log("Advertisement Data ▲")
                } else {
                    log("Advertisement Data is empty")
                }
                
                if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                    let bytes = [UInt8](data)
                    if bytes.count >= 2 {
                        let companyId = UInt16(bytes[1]) << 8 | UInt16(bytes[0])
                        let payload = bytes.dropFirst(2)
                            .map { String(format: "%02X", $0) }
                            .joined(separator: " ")
                        log("""
                               Manufacturer Data:
                                 • Length: \(bytes.count)
                                 • Company ID: 0x\(String(format: "%04X", companyId))
                                 • Payload (HEX): \(payload)
                               """)
                    } else {
                        log("Manufacturer data too short: \(bytes.count) bytes")
                    }
                }
                
                if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID], !serviceUUIDs.isEmpty {
                    let uuids = serviceUUIDs.map { $0.uuidString.lowercased() }
                    log("Advertised Service UUIDs: \(uuids.joined(separator: ", "))")
                } else {
                    log("Service UUIDs are empty")
                }
                
                if !devices.contains(where: { $0.identifier == id }) {
                    devices.append(DiscoveredDevice(name: deviceName, identifier: id, rssi: rssi))
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                log("============================")
            case let .scanStopped(peripherals, error):
                if let error {
                    log("Scan stopped with error: \(error.localizedDescription)")
                } else {
                    log("Scan Stopped. Found \(peripherals.count) peripherals.")
                }
            }
        }
    }
    
    private func configureNavigationLeftBarButtonItemButtons() {
        navigationItem.leftBarButtonItem = createNavbarButton(title: localizedString("shared_string_close"),
                                                              icon: nil,
                                                              color: .iconColorActive,
                                                              action: #selector(onCloseBarButtonActon),
                                                              target: self,
                                                              menu: nil)
        
        navigationItem.rightBarButtonItem = createNavbarButton(title: nil, icon: .icCustomExportOutlined, color: .iconColorActive, action: #selector(onSharedBarButtonActon(_:)), target: self, menu: nil)
    }

    @objc private func sendLogFile(sender: UIBarButtonItem) {
        let fileManager = FileManager.default

        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let logsPath = documentsURL.appendingPathComponent("Logs")

        guard let files = try? fileManager.contentsOfDirectory(atPath: logsPath.path), !files.isEmpty else {
            return
        }

        let sortedFiles = files.sorted { file1, file2 in
            let path1 = logsPath.appendingPathComponent(file1).path
            let path2 = logsPath.appendingPathComponent(file2).path
            let attr1 = try? fileManager.attributesOfItem(atPath: path1)
            let attr2 = try? fileManager.attributesOfItem(atPath: path2)
            let date1 = attr1?[.creationDate] as? Date ?? .distantPast
            let date2 = attr2?[.creationDate] as? Date ?? .distantPast
            return date1 > date2
        }

        guard let latestLogFile = sortedFiles.first else {
            return
        }

        let latestLogURL = logsPath.appendingPathComponent(latestLogFile)
        
        showActivity([latestLogURL], sourceView: view, barButtonItem: sender)
    }
    
    @objc private func onCloseBarButtonActon(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func onSharedBarButtonActon(_ sender: UIBarButtonItem) {
        sendLogFile(sender: sender)
    }
}

// MARK: - UITableViewDataSource
extension BLEScannerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        let device = devices[indexPath.row]
        cell.textLabel?.text = "\(device.name) (\(device.rssi) dBm)"
        cell.detailTextLabel?.text = device.identifier
        return cell
    }
}

// MARK: - UITableViewDelegate
extension BLEScannerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDevice = devices[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        
        log("Selected device: \(selectedDevice.name) [\(selectedDevice.identifier)], RSSI: \(selectedDevice.rssi)")
    }
}
