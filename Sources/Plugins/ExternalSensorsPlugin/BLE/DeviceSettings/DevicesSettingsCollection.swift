//
//  DevicesSettingsCollection.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class DevicesSettingsCollection {
    
    private let storage = UserDefaults.standard
    
    var hasPairedDevices: Bool {
        if let deviceSettingsArray: [DeviceSettings] = storage[.deviceSettings], !deviceSettingsArray.isEmpty {
           return true
        }
        return false
    }
    
    func getSettingsForPairedDevices() -> [DeviceSettings]? {
        storage.object([DeviceSettings].self, with: UserDefaultsKey.deviceSettings.rawValue)
    }
    
    func getDeviceSettings(deviceId: String) -> DeviceSettings? {
        guard let deviceSettingsArray: [DeviceSettings] = storage[.deviceSettings],
              let deviceSettings = deviceSettingsArray.first(where: { $0.deviceId == deviceId }) else {
            return nil
        }
        return deviceSettings
    }
    
    func removeDeviceSetting(with id: String) {
        if var deviceSettingsArray: [DeviceSettings] = storage[.deviceSettings],
           let index = deviceSettingsArray.firstIndex(where: { $0.deviceId == id }) {
            deviceSettingsArray.remove(at: index)
            storage[.deviceSettings] = deviceSettingsArray
        }
    }
    
    func createDeviceSettings(device: Device, deviceEnabled: Bool) {
        var deviceSettings: DeviceSettings
        switch device.deviceType {
        case .BLE_BICYCLE_SCD:
            deviceSettings = WheelDeviceSettings(deviceId: device.id, deviceType: device.deviceType, deviceName: device.deviceName, deviceEnabled: deviceEnabled)
        default:
            deviceSettings = DeviceSettings(deviceId: device.id, deviceType: device.deviceType, deviceName: device.deviceName, deviceEnabled: deviceEnabled)
        }
        addDeviceSettings(item: deviceSettings)
    }
    
    func changeDeviceName(with id: String, name: String) {
        guard let deviceSettings = getDeviceSettings(deviceId: id) else { return }
        deviceSettings.deviceName = name
        updateDeviceSettings(item: deviceSettings)
    }
    
    func changeDeviceParameter(with id: String,
                               key: String,
                               value: String) {
        guard let deviceSettings = getDeviceSettings(deviceId: id) else { return }
        deviceSettings.setDeviceProperty(key: key, value: value)
        updateDeviceSettings(item: deviceSettings)
    }
    
    private func addDeviceSettings(item: DeviceSettings) {
        if var deviceSettingsArray: [DeviceSettings] = storage[.deviceSettings] {
            deviceSettingsArray.append(item)
            storage[.deviceSettings] = deviceSettingsArray
        } else {
            storage[.deviceSettings] = [item]
        }
    }
    
    private func updateDeviceSettings(item: DeviceSettings) {
        if var deviceSettingsArray: [DeviceSettings] = storage[.deviceSettings],
           let deviceSettingsIndex = deviceSettingsArray.firstIndex(where: { $0.deviceId == item.deviceId }) {
            deviceSettingsArray[deviceSettingsIndex] = item
            storage[.deviceSettings] = deviceSettingsArray
        }
    }
}
