//
//  BLEManager.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 22.09.2023.
//

import CoreBluetooth
import OSLog

enum BLEManagerUnavailbleFailureReason: String {
    case unsupported = "Your iOS device does not support Bluetooth."
    case unauthorized = "Unauthorized to use Bluetooth."
    case poweredOff = "Bluetooth is disabled, enable bluetooth and try again."
    case unknown = "Bluetooth is currently unavailable (unknown reason)."
    case scanningEndedUnexpectedly
}

final class BLEManager {
    static let shared = BLEManager()
    
    var isScaning: Bool {
        SwiftyBluetooth.isScanning
    }
    
    private(set) var discoveredDevices = [Device]()
    
    private var restoreStateObserver: NSObjectProtocol?
    private var centralStateObserver: NSObjectProtocol?
    
    private init() {
        restoreStateObserver = NotificationCenter.default.addObserver(forName: Central.CentralManagerWillRestoreState,
                                                                      object: nil,
                                                                      queue: nil) { [weak self] notification in
            guard let self,
                  let restoredPeripherals = notification.userInfo?["peripherals"] as? [Peripheral],
                  !restoredPeripherals.isEmpty else {
                return
            }
            
            NSLog("BLEManager -> restoredPeripherals: \(restoredPeripherals)")
            
            guard let pairedDevices = DeviceHelper.shared.getSettingsForPairedDevices() else {
                NSLog("BLEManager -> restoreConnectedDevices: pairedDevices is empty")
                return
            }
            
            let devices = DeviceHelper.shared.getDevicesFrom(peripherals: restoredPeripherals, pairedDevices: pairedDevices)
            
            let nonOBDDevices = devices.filter { $0.deviceType != .OBD_VEHICLE_METRICS }
            let obdDevices = devices.filter { $0.deviceType == .OBD_VEHICLE_METRICS }
            
            handleRestoredDevices(devices: nonOBDDevices, isAllowed: OAIAPHelper.isSensorPurchased())
            handleRestoredDevices(devices: obdDevices, isAllowed: OAIAPHelper.isVehicleMetricsPurchased())
        }
        
        centralStateObserver = NotificationCenter.default.addObserver(forName: Central.CentralStateChange,
                                                                      object: Central.sharedInstance,
                                                                      queue: nil) { notification in
            guard let state = notification.userInfo?["state"] as? CBManagerState else {
                return
            }
            if case .poweredOff = state {
                if OAIAPHelper.isOsmAndProAvailable() || OAIAPHelper.isMapsPlusAvailable() {
                    // Peripheral that are no longer valid must be rediscovered again (happens when for example the Bluetooth is turned off
                    // from a user's phone and turned back on
                    DeviceHelper.shared.disconnectDevices(reason: .bluetoothPoweredOff)
                }
            }
        }
    }
    
    func scanForPeripherals(withServiceUUIDs serviceUUIDs: [CBUUID]? = nil,
                            timeoutAfter timeout: TimeInterval = 15,
                            successHandler: @escaping () -> Void,
                            failureHandler: @escaping (BLEManagerUnavailbleFailureReason) -> Void,
                            scanStoppedHandler: @escaping (Bool) -> Void) {
        discoveredDevices.removeAll()
        SwiftyBluetooth.scanForPeripherals(withServiceUUIDs: serviceUUIDs, timeoutAfter: timeout) { [weak self] scanResult in
            guard let self else { return }
            switch scanResult {
            case .scanStarted:
                NSLog("BLEManager -> Scan Started")
            case let .scanResult(peripheral, advertisementData, RSSI):
                let rssi = RSSI ?? -1
                NSLog("BLEManager -> Peripheral Identifier: \(peripheral.identifier.uuidString), RSSI: \(rssi)")
                NSLog("BLEManager -> peripheral Name: \(peripheral.name ?? "nil")")
                
                if !advertisementData.isEmpty {
                    NSLog("BLEManager -> Advertisement Data ▼")
                    for (key, value) in advertisementData {
                        NSLog(" • \(key): \(value)")
                    }
                    NSLog("BLEManager -> Advertisement Data ▲")
                } else {
                    NSLog("BLEManager -> Advertisement Data is empty")
                }
                
                if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                    let bytes = [UInt8](data)
                    if bytes.count >= 2 {
                        let companyId = UInt16(bytes[1]) << 8 | UInt16(bytes[0])
                        let payload = bytes.dropFirst(2)
                            .map { String(format: "%02X", $0) }
                            .joined(separator: " ")
                        NSLog("""
                                BLEManager -> Manufacturer Data:
                                 • Length: \(bytes.count)
                                 • Company ID: 0x\(String(format: "%04X", companyId))
                                 • Payload (HEX): \(payload)
                               """)
                    } else {
                        NSLog("BLEManager -> Manufacturer data too short: \(bytes.count) bytes")
                    }
                }
                
                guard let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID], !serviceUUIDs.isEmpty else {
                    NSLog("BLEManager -> Service UUIDs are empty")
                    NSLog("============================")
                    return
                }
                let uuids = serviceUUIDs.map { $0.uuidString.lowercased() }
                
                NSLog("BLEManager -> Advertised Service UUIDs: \(uuids.joined(separator: ", "))")
                
                if let device = DeviceHelper.shared.connectedDevices.first(where: { $0.id == peripheral.identifier.uuidString }) {
                    device.setPeripheral(peripheral: peripheral)
                    device.addObservers()
                    discoveredDevices.append(device)
                    successHandler()
                } else {
                    if let device = DeviceFactory.createDevice(with: uuids) {
                        var deviceName = advertisementData["kCBAdvDataLocalName"] as? String ?? peripheral.name ?? device.deviceServiceName
                        if let savedDevice = DeviceHelper.shared.devicesSettingsCollection.getDeviceSettings(deviceId: peripheral.identifier.uuidString) {
                            deviceName = savedDevice.deviceName
                        }
                        NSLog("BLEManager -> Device Name: \(deviceName)")
                        device.setPeripheral(peripheral: peripheral)
                        device.rssi = rssi
                        device.deviceName = deviceName
                        device.addObservers()
                        discoveredDevices.append(device)
                        successHandler()
                    } else {
                        NSLog("BLEManager -> Unknown device found: \(peripheral.name ?? "Unknown")")
                    }
                }
                NSLog("============================")
            case let .scanStopped(peripherals, error):
                // The scan stopped, an error is passed if the scan stopped unexpectedly
                if let error {
                    NSLog("BLEManager -> Scan stopped with error: \(error.localizedDescription)")
                    var _error: BLEManagerUnavailbleFailureReason
                    switch error {
                    case .bluetoothUnavailable(reason: let reason):
                        switch reason {
                        case .unsupported:
                            _error = .unsupported
                        case .unauthorized:
                            _error = .unauthorized
                        case .poweredOff:
                            _error = .poweredOff
                        case .unknown:
                            _error = .unknown
                        }
                    case .scanningEndedUnexpectedly:
                        _error = .scanningEndedUnexpectedly
                    default:
                        fatalError(error.localizedDescription)
                    }
                    failureHandler(_error)
                } else {
                    NSLog("BLEManager -> Scan Stopped")
                    scanStoppedHandler(!peripherals.isEmpty)
                }
            }
        }
    }
    
    func removeAndDisconnectDiscoveredDevices() {
        discoveredDevices.forEach {
            $0.disableRSSI()
            DeviceHelper.shared.disconnectIfNeeded(device: $0)
        }
        discoveredDevices.removeAll()
    }
    
    func stopScan() {
        SwiftyBluetooth.stopScan()
    }
    
    func getBluetoothState() -> CBManagerState {
        Central.sharedInstance.state
    }
    
    func asyncState(completion: @escaping (CBManagerState) -> Void) {
        SwiftyBluetooth.asyncState { _ in
            completion(Central.sharedInstance.state)
        }
    }
    
    func removeAllDiscoveredDevices() {
        discoveredDevices.removeAll()
    }
    
    private func handleRestoredDevices(devices: [Device], isAllowed: Bool) {
        guard !devices.isEmpty else { return }
        
        if isAllowed {
            DeviceHelper.shared.updateConnected(devices: devices)
        } else {
            devices.forEach { $0.disconnect(completion: { _ in }) }
        }
    }
    
    deinit {
        if let observer = restoreStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = centralStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
