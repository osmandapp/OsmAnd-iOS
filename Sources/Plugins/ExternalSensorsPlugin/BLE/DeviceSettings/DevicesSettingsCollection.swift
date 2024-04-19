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
    
    //    private static DEVICES_SETTINGS_PREF_ID = "external_devices_settings"
    //
    //    private final CommonPreference<String> preference;
    //    private final Gson gson;
    //    private final Map<String, DeviceSettings> settings = new HashMap<>();
    //    private List<DevicePreferencesListener> listeners = new ArrayList<>();
    
    
    //    public interface DevicePreferencesListener {
    //        void onDeviceEnabled(@NonNull String deviceId);
    //
    //        void onDeviceDisabled(@NonNull String deviceId);
    //    }
    
    //    public DevicesSettingsCollection(@NonNull ExternalSensorsPlugin plugin) {
    //        gson = new GsonBuilder().create();
    //        preference = plugin.registerStringPref(DEVICES_SETTINGS_PREF_ID, "");
    //        readSettings();
    //    }
    
    
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
        if let deviceSettings = getDeviceSettings(deviceId: id) {
            deviceSettings.deviceName = name
            updateDeviceSettings(item: deviceSettings)
        }
    }
    
    func changeWheelSize(with id: String, size: Float) {
        if let deviceSettings = getDeviceSettings(deviceId: id) {
            if var additionalParams = deviceSettings.additionalParams {
                additionalParams[WheelDeviceSettings.WHEEL_CIRCUMFERENCE_KEY] = String(describing: size)
                deviceSettings.additionalParams = additionalParams
                updateDeviceSettings(item: deviceSettings)
            }
        }
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

