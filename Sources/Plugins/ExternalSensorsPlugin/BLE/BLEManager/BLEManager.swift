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
        subsystem: Bundle.main.bundleIdentifier ?? "OsmAnd",
        category: String(describing: BLEManager.self)
    )
    
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
            
            debugPrint(restoredPeripherals)
            
            guard let pairedDevices = DeviceHelper.shared.getSettingsForPairedDevices() else {
                Self.logger.warning("restoreConnectedDevices: pairedDevices is empty")
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
                    DeviceHelper.shared.disconnectAllDevices(reason: .bluetoothPoweredOff)
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
                        var deviceName = advertisementData["kCBAdvDataLocalName"] as? String ?? peripheral.name ?? device.deviceServiceName
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
