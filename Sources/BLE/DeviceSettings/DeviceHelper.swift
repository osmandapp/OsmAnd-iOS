//
//  DeviceHelper.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class DeviceHelper {
    static let shared = DeviceHelper()
    
    let devicesSettingsCollection = DevicesSettingsCollection()
    
    private init() {}
    
    func isDeviceEnabled(for id: String) -> Bool {
        if let deviceSettings = devicesSettingsCollection.getDeviceSettings(deviceId: id) {
            return deviceSettings.deviceEnabled
        }
        return false
    }
    
    func setDevicePaired(device: Device, isPaired: Bool) {
        if isPaired {
            if devicesSettingsCollection.getDeviceSettings(deviceId: device.id) == nil {
                devicesSettingsCollection.createDeviceSettings(device: device, deviceEnabled: true)
            }
        } else {
            dropUnpairedDevice(device: device)
        }
    }
    
    func changeDeviceName(with id: String, name: String) {
        devicesSettingsCollection.changeDeviceName(with: id, name: name)
    }
    
    private func dropUnpairedDevice(device: Device) {
        device.peripheral.disconnect { result in }
        devicesSettingsCollection.removeDeviceSetting(with: device.id)
    }
}
