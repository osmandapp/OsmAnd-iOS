//
//  DeviceHelper.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import CoreBluetooth
import OSLog

@objc(OADeviceHelper)
@objcMembers
final class DeviceHelper: NSObject {
    static let shared = DeviceHelper()
    
    let devicesSettingsCollection = DevicesSettingsCollection()
    
    func hasPairedDevices(ofType deviceType: DeviceType) -> Bool {
        devicesSettingsCollection.hasPairedDevices(ofType: deviceType)
    }
    
    func hasPairedDevices(excludingType deviceType: DeviceType) -> Bool {
        devicesSettingsCollection.hasPairedDevices(excludingType: deviceType)
    }
    
    func connectedDevices(ofType deviceType: DeviceType) -> [Device] {
        connectedDevices.filter { $0.deviceType == deviceType }
    }
    
    func connectedDevices(excludingType deviceType: DeviceType) -> [Device] {
        connectedDevices.filter { $0.deviceType != deviceType }
    }
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "OsmAnd",
        category: String(describing: DeviceHelper.self)
    )
    
    private(set) var connectedDevices = [Device]()
    
    private override init() {}
    
    func getConnectedDevicesForWidget(type: WidgetType) -> [Device]? {
        connectedDevices.filter { $0.getSupportedWidgetDataFieldTypes()?.contains(type) ?? false }
    }
    
    func getDisconnectedDevices(for pairedDevices: [DeviceSettings]) -> [Device] {
        let peripherals = SwiftyBluetooth.retrievePeripherals(withUUIDs: pairedDevices.compactMap { UUID(uuidString: $0.deviceId) })
        updatePeripheralsForConnectedDevices(peripherals: peripherals.filter { $0.state == .connected })
        let disconnectedPeripherals = peripherals.filter { $0.state != .connected }
        
        return getDevicesFrom(peripherals: disconnectedPeripherals, pairedDevices: pairedDevices)
    }
    
    func getPairedDevicesFor(type: WidgetType, deviceId: String) -> Device? {
        getPairedDevicesFor(type: type)?.first { $0.id == deviceId }
    }
    
    func getPairedDevicesFor(type: WidgetType) -> [Device]? {
        if let pairedDevices = getSettingsForPairedDevices() {
            let peripherals = SwiftyBluetooth.retrievePeripherals(withUUIDs: pairedDevices.map { UUID(uuidString: $0.deviceId)! })
            let connectedPeripherals = peripherals.filter { $0.state == .connected }
            updatePeripheralsForConnectedDevices(peripherals: connectedPeripherals)
            
            let disconnectedPeripherals = peripherals.filter { $0.state != .connected }
            let disconnectedDevices = getDevicesFrom(peripherals: disconnectedPeripherals,
                                                     pairedDevices: pairedDevices)
            
            let devices = connectedDevices + disconnectedDevices
            return devices.filter { $0.getSupportedWidgetDataFieldTypes()?.contains(type) ?? false }
        }
        return nil
    }
    
    func getConnectedAndDisconnectedDevicesForWidget(type: WidgetType) -> [Device]? {
        connectedDevices.filter { $0.getSupportedWidgetDataFieldTypes()?.contains(type) ?? false }
    }
    
    func getSettingsForPairedDevices(matching type: DeviceType) -> [DeviceSettings]? {
        getSettingsForPairedDevices()?.filter { $0.deviceType == type }
    }
    
    func getSettingsForPairedDevices(excluding type: DeviceType) -> [DeviceSettings]? {
        getSettingsForPairedDevices()?.filter { $0.deviceType != type }
    }
    
    func getSettingsForPairedDevices() -> [DeviceSettings]? {
        devicesSettingsCollection.getSettingsForPairedDevices()
    }
    
    func getDevicesFrom(peripherals: [Peripheral], pairedDevices: [DeviceSettings]) -> [Device] {
        return peripherals.compactMap { peripheral in
            if let savedDevice = pairedDevices.first(where: { $0.deviceId == peripheral.identifier.uuidString }) {
                let device = getDeviceFor(type: savedDevice.deviceType)
                device.deviceName = savedDevice.deviceName
                device.deviceType = savedDevice.deviceType
                device.setPeripheral(peripheral: peripheral)
                device.configure()
                device.addObservers()
                return device
            } else {
                return nil
            }
        }
    }
    
    func isDeviceEnabled(for id: String) -> Bool {
        if let deviceSettings = devicesSettingsCollection.getDeviceSettings(deviceId: id) {
            return deviceSettings.deviceEnabled
        }
        return false
    }
    
    func setDevicePaired(device: Device, isPaired: Bool) {
        if isPaired {
            if !isPairedDevice(id: device.id) {
                devicesSettingsCollection.createDeviceSettings(device: device, deviceEnabled: true)
            }
        } else {
            dropUnpairedDevice(device: device)
        }
    }
    
    func isPairedDevice(id: String) -> Bool {
        devicesSettingsCollection.getDeviceSettings(deviceId: id) != nil
    }
    
    func changeDeviceName(with id: String, name: String) {
        devicesSettingsCollection.changeDeviceName(with: id, name: name)
    }
    
    func changeDeviceParameter(with id: String,
                               key: String,
                               value: String) {
        devicesSettingsCollection.changeDeviceParameter(with: id,
                                                        key: key,
                                                        value: value)
        if key == WheelDeviceSettings.WHEEL_CIRCUMFERENCE_KEY {
            if let connectedDevice = connectedDevices.first(where: { $0.id == id }) as? BLEBikeSCDDevice,
               let wheelCircumference = Double(value) {
                connectedDevice.setWheelCircumference(wheelCircumference: wheelCircumference)
            }
        }
    }
    
    private func updatePeripheralsForConnectedDevices(peripherals: [Peripheral]) {
        for peripheral in peripherals {
            if let index = connectedDevices.firstIndex(where: { $0.id == peripheral.identifier.uuidString }) {
                connectedDevices[index].setPeripheral(peripheral: peripheral)
                connectedDevices[index].addObservers()
            }
        }
    }
    
    private func unpairWidgetsForDevice(id: String) {
        let widgets = getWidgetsForExternalDevice(id: id)
        if !widgets.isEmpty {
            widgets.forEach {
                // reset to default state
                $0.configureDevice(id: "")
                $0.setAnyDevice(use: true)
            }
        }
    }
    
    private func getWidgetsForExternalDevice(id: String) -> [SensorTextWidget] {
        if let widgetInfos = OAMapWidgetRegistry.sharedInstance().getAllWidgets(), !widgetInfos.isEmpty {
            return widgetInfos
                .compactMap { $0.widget as? SensorTextWidget }
                .filter { ($0.externalDeviceId ?? "") == id }
        }
        return []
    }
    
    private func dropUnpairedDevice(device: Device) {
        device.disableRSSI()
        disconnectIfNeeded(device: device)
        removeDisconnected(device: device)
        devicesSettingsCollection.removeDeviceSetting(with: device.id)
        unpairWidgetsForDevice(id: device.id)
        unpairTrackRecordingFor(device: device)
    }
    
    private func unpairTrackRecordingFor(device: Device) {
        guard let supportedTypes = device.getSupportedWidgetDataFieldTypes(),
              let plugin = OAPluginsHelper.getEnabledPlugin(OAExternalSensorsPlugin.self) as? OAExternalSensorsPlugin else { return }
        supportedTypes.forEach {
            let deviceId = plugin.getDeviceId(for: $0, appMode: OAAppSettings.sharedManager().applicationMode.get())
            if !deviceId.isEmpty {
                plugin.getWriteToTrackDeviceIdPref($0)?.resetToDefault()
            }
        }
    }
    
    private func getDeviceFor(type: DeviceType) -> Device {
        switch type {
        case .BLE_HEART_RATE:
            return BLEHeartRateDevice()
        case .BLE_TEMPERATURE:
            return BLETemperatureDevice()
        case .BLE_BICYCLE_SCD:
            return BLEBikeSCDDevice()
        case .BLE_RUNNING_SCDS:
            return BLERunningSCDDevice()
        case .OBD_VEHICLE_METRICS:
            return OBDVehicleMetricsDevice()
        default:
            fatalError("not impl")
        }
    }
}

extension DeviceHelper {
    
    @objc enum DisconnectDeviceReason: Int {
        case pluginOff, bluetoothPoweredOff
    }
    
    func disconnectIfNeeded(device: Device) {
        if device.isConnected || device.isConnecting {
            device.peripheral.disconnect { result in
                switch result {
                case .success:
                    NSLog("[DeviceHelper] - success | disconnectIfNeeded | id: \(device.id) | name: \(device.deviceName)")
                case .failure(let error):
                    NSLog("[DeviceHelper] - failure | disconnectIfNeeded | id: \(device.id) | name: \(device.deviceName) | error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // objc compatibility
    func disconnectAllSensorDevices(reason: DisconnectDeviceReason) {
        disconnectDevices(excluding: .OBD_VEHICLE_METRICS, reason: reason)
    }
    
    func disconnectDevices(reason: DisconnectDeviceReason) {
        disconnectFilteredDevices(reason: reason) { _ in true }
    }
    
    func disconnectDevices(only deviceType: DeviceType, reason: DisconnectDeviceReason) {
        disconnectFilteredDevices(reason: reason) { $0.deviceType == deviceType }
    }
    
    func disconnectDevices(excluding deviceType: DeviceType, reason: DisconnectDeviceReason) {
        disconnectFilteredDevices(reason: reason) { $0.deviceType != deviceType }
    }
    
    func addConnected(device: Device) {
        guard !connectedDevices.contains(where: { $0.id == device.id }) else {
            NSLog("addConnected device is already exists")
            return
        }
        connectedDevices.append(device)
        if let discoveredDevice = BLEManager.shared.discoveredDevices.first(where: { $0.id == device.id && $0.deviceType != .OBD_VEHICLE_METRICS }) {
            discoveredDevice.notifyRSSI()
        }
        if let connectedDevice = connectedDevices.first(where: { $0.id == device.id && $0.deviceType != .OBD_VEHICLE_METRICS }) {
            connectedDevice.notifyRSSI()
        }
    }
    
    func removeDisconnected(device: Device) {
        if let discoveredDevice = BLEManager.shared.discoveredDevices.first(where: { $0.id == device.id }) {
            discoveredDevice.disableRSSI()
            disconnectIfNeeded(device: discoveredDevice)
        }
        if let connectedDevice = connectedDevices.first(where: { $0.id == device.id }) {
            connectedDevice.disableRSSI()
            disconnectIfNeeded(device: connectedDevice)
        }
        connectedDevices = connectedDevices.filter { $0.id != device.id }
    }
    
    func updateConnected(devices: [Device]) {
        devices.forEach { device in
            if !connectedDevices.contains(where: { $0.id == device.id }) {
                device.connect(withTimeout: 10) { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success:
                        debugPrint("updateConnected success | \(device.deviceServiceName) | \(device.deviceName)")
                        device.addObservers()
                        device.notifyRSSI()
                        setDevicePaired(device: device, isPaired: true)
                        connectedDevices.append(device)
                        discoverServices(device: device)
                    case .failure(let error):
                        Self.logger.error("updateConnected failure: \(String(describing: error.localizedDescription))")
                    }
                }
            }
        }
    }
    
    private func disconnectFilteredDevices(reason: DisconnectDeviceReason, filter: (Device) -> Bool) {
        let devicesToDisconnect: [Device]
        
        switch reason {
        case .pluginOff:
            devicesToDisconnect = connectedDevices.filter(filter)
            BLEManager.shared.removeAndDisconnectDiscoveredDevices()
        case .bluetoothPoweredOff:
            devicesToDisconnect = connectedDevices
        }
        
        for device in devicesToDisconnect {
            device.disableRSSI()
            disconnectIfNeeded(device: device)
        }
        
        let idsToRemove = Set(devicesToDisconnect.map { $0.id })
        connectedDevices.removeAll { idsToRemove.contains($0.id) }
    }
    
    private func discoverServices(device: Device, serviceUUIDs: [CBUUID]? = nil) {
        device.discoverServices(withUUIDs: nil) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let services):
                discoverCharacteristics(device: device, services: services)
            case .failure(let error):
                Self.logger.error("discoverServices: \(String(describing: error.localizedDescription))")
            }
        }
    }
    
    private func discoverCharacteristics(device: Device, services: [CBService]) {
        var completedCount = 0
        let totalServices = services.count
        for service in services {
            device.discoverCharacteristics(withUUIDs: nil, ofServiceWithUUID: service.uuid) { result in
                defer {
                    completedCount += 1
                    if completedCount == totalServices, device.deviceType == .OBD_VEHICLE_METRICS {
                        OBDService.shared.startDispatcher()
                    }
                }
                
                switch result {
                case .success(let characteristics):
                    for characteristic in characteristics {
                        if characteristic.properties.contains(.read) {
                            device.update(with: characteristic) { _ in }
                        }
                        if characteristic.properties.contains(.notify) {
                            device.setNotifyValue(toEnabled: true, ofCharac: characteristic) { _ in }
                        }
                    }
                case .failure(let error):
                    Self.logger.error("discoverCharacteristics: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension DeviceHelper {
    func getOBDDevice() -> OBDVehicleMetricsDevice? {
        connectedDevices.first(where: { $0.deviceType == .OBD_VEHICLE_METRICS }) as? OBDVehicleMetricsDevice
    }
}
