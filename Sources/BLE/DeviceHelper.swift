//
//  DeviceHelper.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import SwiftyBluetooth
import CoreBluetooth
import OSLog

@objcMembers
final class DeviceHelper: NSObject {
    static let shared = DeviceHelper()
    
    let devicesSettingsCollection = DevicesSettingsCollection()
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: DeviceHelper.self)
    )
    
    private override init() {}
    
    var hasPairedDevices: Bool {
        devicesSettingsCollection.hasPairedDevices
    }
    
    private(set) var connectedDevices = [Device]()
    
    func disconnectAllDevices() {
        guard !connectedDevices.isEmpty else { return }
        connectedDevices.forEach { 
            $0.disableRSSI()
            $0.peripheral.disconnect(completion: { _ in })
        }
        connectedDevices.removeAll()
        BLEManager.shared.removeDiscoveredDevices()
    }
    
    func restoreConnectedDevices(with peripherals: [Peripheral]) {
        if let pairedDevices = DeviceHelper.shared.getSettingsForPairedDevices() {
            let devices = DeviceHelper.shared.getDevicesFrom(peripherals: peripherals, pairedDevices: pairedDevices)
            updateConnected(devices: devices)
        } else {
            Self.logger.warning("restoreConnectedDevices peripherals is empty")
        }
    }
    
    private func updateConnected(devices: [Device]) {
        print("updateConnected")
        devices.forEach { device in
            if !connectedDevices.contains(where: { $0.id == device.id }) {
                device.peripheral.connect(withTimeout: 10) { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success:
                        print("updateConnected success")
                        device.addObservers()
                        device.notifyRSSI()
                        DeviceHelper.shared.setDevicePaired(device: device, isPaired: true)
                        connectedDevices.append(device)
                        discoverServices(device: device)
                    case .failure(let error):
                        Self.logger.error("updateConnected connect: \(String(describing: error.localizedDescription))")
                    }
                }
            }
        }
    }
    
    private func discoverServices(device: Device, serviceUUIDs: [CBUUID]? = nil) {
        device.peripheral.discoverServices(withUUIDs: nil) { [weak self] result in
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
        for service in services {
            device.peripheral.discoverCharacteristics(withUUIDs: nil, ofServiceWithUUID: service.uuid) { result in
                switch result {
                case .success(let characteristics):
                    for characteristic in characteristics {
                        debugPrint(characteristic)
                        if characteristic.properties.contains(.read) {
                            device.update(with: characteristic) { _ in }
                        }
                        if characteristic.properties.contains(.notify) {
                            debugPrint("\(characteristic.uuid): properties contains .notify")
                            device.peripheral.setNotifyValue(toEnabled: true, ofCharac: characteristic) { result in
                                debugPrint(result)
                            }
                        }
                    }
                case .failure(let error):
                    Self.logger.error("discoverCharacteristics: \(String(describing: error.localizedDescription))")
                    break
                }
            }
        }
    }
    
    func addConnected(device: Device) {
        guard !connectedDevices.contains(where: { $0.id == device.id }) else {
            return
        }
        connectedDevices.append(device)
        print("addConnected: \(connectedDevices)")
        if let discoveredDevice = BLEManager.shared.discoveredDevices.first(where: { $0.id == device.id }) {
            discoveredDevice.notifyRSSI()
        }
        if let connectedDevice = connectedDevices.first(where: { $0.id == device.id }) {
            connectedDevice.notifyRSSI()
        }
    }
    
    func removeDisconnected(device: Device) {
        connectedDevices = connectedDevices.filter { $0.id != device.id }
        print("remove: \(connectedDevices)")
        if let discoveredDevice = BLEManager.shared.discoveredDevices.first(where: { $0.id == device.id }) {
            discoveredDevice.disableRSSI()
            discoveredDevice.peripheral.disconnect { _ in }
        }
        if let connectedDevice = connectedDevices.first(where: { $0.id == device.id }) {
            connectedDevice.disableRSSI()
            connectedDevice.peripheral.disconnect { _ in }
        }
    }
    
    func getSettingsForPairedDevices() -> [DeviceSettings]? {
        devicesSettingsCollection.getSettingsForPairedDevices()
    }
    
    func getDevicesFrom(peripherals: [Peripheral], pairedDevices: [DeviceSettings]) -> [Device] {
        return peripherals.map { item in
            if let savedDevice = pairedDevices.first(where: { $0.deviceId == item.identifier.uuidString }) {
                let device = getDeviceFor(type: savedDevice.deviceType)
                device.deviceName = savedDevice.deviceName
                device.deviceType = savedDevice.deviceType
                device.peripheral = item
                device.addObservers()
                return device
            } else {
                fatalError("getDevicesFrom")
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
    
    private func dropUnpairedDevice(device: Device) {
        device.disableRSSI()
        device.peripheral.disconnect { result in }
        removeDisconnected(device: device)
        devicesSettingsCollection.removeDeviceSetting(with: device.id)
    }
    
    private func getDeviceFor(type: DeviceType) -> Device {
        switch type {
        case .BLE_HEART_RATE:
            return BLEHeartRateDevice()
        default:
            fatalError("not impl")
        }
    }
}

extension DeviceHelper {
    func clearPairedDevices() {
        // add test func
    }
}
