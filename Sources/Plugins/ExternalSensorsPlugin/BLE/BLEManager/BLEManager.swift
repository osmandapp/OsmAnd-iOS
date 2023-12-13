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
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: BLEManager.self)
    )
    
    var isScaning: Bool {
        SwiftyBluetooth.isScanning
    }
    
    private(set) var discoveredDevices = [Device]()
    
    private init() {
        NotificationCenter.default.addObserver(forName: Central.CentralManagerWillRestoreState,
                                               object: nil,
                                               queue: nil) { notification in
            if let restoredPeripherals = notification.userInfo?["peripherals"] as? [Peripheral], !restoredPeripherals.isEmpty {
                debugPrint(restoredPeripherals)
                if OAIAPHelper.isOsmAndProAvailable() {
                    DeviceHelper.shared.restoreConnectedDevices(with: restoredPeripherals)
                } else {
                    restoredPeripherals.forEach {
                        $0.disconnect(completion: { _ in }) }
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: Central.CentralStateChange,
                                               object: Central.sharedInstance,
                                               queue: nil) { notification in
            guard let state = notification.userInfo?["state"] as? CBManagerState else {
                return
            }
            if case .poweredOff = state {
                if OAIAPHelper.isOsmAndProAvailable() {
                    // Peripheral that are no longer valid must be rediscovered again (happens when for example the Bluetooth is turned off
                    // from a user's phone and turned back on
                    DeviceHelper.shared.disconnectAllDevices(direction: .bluetoothPoweredOff)
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
                Self.logger.debug("BLEManager -> scanStarted")
            case let .scanResult(peripheral, advertisementData, RSSI):
                let rssi = RSSI ?? -1
                Self.logger.debug("BLEManager -> peripheral identifier: \(peripheral.identifier) RSSI: \(rssi)")
                guard let serviceUUIDs = (advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID]), !serviceUUIDs.isEmpty else {
                    Self.logger.error("BLEManager -> serviceUUIDs is empty")
                    return
                }
                if let device = DeviceHelper.shared.connectedDevices.first(where: { $0.id == peripheral.identifier.uuidString }) {
                    device.setPeripheral(peripheral: peripheral)
                    device.addObservers()
                    discoveredDevices.append(device)
                    successHandler()
                } else {
                    let uuids = serviceUUIDs.map { $0.uuidString.lowercased() }
                    if let device = DeviceFactory.createDevice(with: uuids) {
                        var deviceName = advertisementData["kCBAdvDataLocalName"] as? String ?? device.deviceServiceName
                        if let savedDevice = DeviceHelper.shared.devicesSettingsCollection.getDeviceSettings(deviceId: peripheral.identifier.uuidString) {
                            deviceName = savedDevice.deviceName
                        }
                        device.setPeripheral(peripheral: peripheral)
                        device.rssi = rssi
                        device.deviceName = deviceName
                        device.addObservers()
                        discoveredDevices.append(device)
                        successHandler()
                    }
                }
            case let .scanStopped(peripherals, error):
                // The scan stopped, an error is passed if the scan stopped unexpectedly
                if let error {
                    Self.logger.error("\(error.localizedDescription)")
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
                        // FIXME:
                        fatalError(error.localizedDescription)
                    }
                    failureHandler(_error)
                } else {
                    Self.logger.debug("BLEManager -> scanStopped")
                    scanStoppedHandler(!peripherals.isEmpty)
                }
            }
        }
    }
    
    func removeAndDisconnectDiscoveredDevices() {
        BLEManager.shared.discoveredDevices.forEach {
            $0.disableRSSI()
            DeviceHelper.shared.disconnectIfNeeded(device: $0)
        }
        BLEManager.shared.discoveredDevices.removeAll()
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
}
