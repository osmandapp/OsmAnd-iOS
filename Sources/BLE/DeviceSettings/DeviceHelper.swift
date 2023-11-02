//
//  DeviceHelper.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import SwiftyBluetooth

final class DeviceHelper {
    static let shared = DeviceHelper()
    
    let devicesSettingsCollection = DevicesSettingsCollection()
    
    private init() {}
    
    var hasPairedDevices: Bool {
        devicesSettingsCollection.hasPairedDevices
    }
    
    func getSettingsForPairedDevices() -> [DeviceSettings]? {
        devicesSettingsCollection.getSettingsForPairedDevices()
    }
    
    func getDevicesFromDeviceSettings(items: [DeviceSettings]) -> [Device] {
        return items.map{ item in
            let device = Device()
            device.deviceName = item.deviceName
            device.deviceType = item.deviceType
            device.addObservers()
            return device
        }
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
                // TODO: use services
               // device.deviceName = item.name ?? ""
                //device.deviceType = savedDevice.deviceType
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
        device.peripheral?.disconnect { result in }
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
