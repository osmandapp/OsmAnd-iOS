//
//  DevicesSettingsCollection.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

enum UserDefaultsKey: String {
    case deviceSettings
}

//extension UserDefaults {
//    func set(_ value: Any, for key: UserDefaultsKey) {
//        set(value, forKey: key.rawValue)
//    }
//
//    func bool(for key: UserDefaultsKey) -> Bool {
//        bool(forKey: key.rawValue)
//    }
//
//    func data(for key: UserDefaultsKey) -> Data? {
//        data(forKey: key.rawValue)
//    }
//
//    func string(for key: UserDefaultsKey) -> String? {
//        string(forKey: key.rawValue)
//    }
//
//    func integer(for key: UserDefaultsKey) -> Int? {
//        integer(forKey: key.rawValue)
//    }
//
//    func float(for key: UserDefaultsKey) -> Float? {
//        float(forKey: key.rawValue)
//    }
//
//    func url(for key: UserDefaultsKey) -> URL? {
//        url(forKey: key.rawValue)
//    }
//
//    func value(for key: UserDefaultsKey) -> Any? {
//        value(forKey: key.rawValue)
//    }
//}

extension UserDefaults {

//    subscript(key: String) -> Any? {
//        get {
//            return object(forKey: key)
//        }
//        set {
//            set(newValue, forKey: key)
//        }
//    }
    
    subscript<T: Codable>(key: UserDefaultsKey) -> T? {
        get {
            return object(T.self, with: key.rawValue)
        }
        set {
            set(object: newValue, forKey: key.rawValue)
        }
    }

    /// Retrieves a Codable object from UserDefaults.
    ///
    /// - Parameters:
    ///   - type: Class that conforms to the Codable protocol.
    ///   - key: Identifier of the object.
    ///   - decoder: Custom JSONDecoder instance. Defaults to `JSONDecoder()`.
    /// - Returns: Codable object for key (if exists).
    func object<T: Codable>(_ type: T.Type, with key: String, usingDecoder decoder: JSONDecoder = JSONDecoder()) -> T? {
        guard let data = value(forKey: key) as? Data else {
            return nil
        }
        return try? decoder.decode(type.self, from: data)
    }

    /// Allows storing of Codable objects to UserDefaults.
    ///
    /// - Parameters:
    ///   - object: Codable object to store.
    ///   - key: Identifier of the object.
    ///   - encoder: Custom JSONEncoder instance. Defaults to `JSONEncoder()`.
    func set<T: Codable>(object: T, forKey key: String, usingEncoder encoder: JSONEncoder = JSONEncoder()) {
        let data = try? encoder.encode(object)
        set(data, forKey: key)
    }
}

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

    func getDeviceSettings(deviceId: String) -> DeviceSettings? {
        if let deviceSettingsArray = storage.object([DeviceSettings].self, with: UserDefaultsKey.deviceSettings.rawValue),
           let deviceSettings = deviceSettingsArray.first(where: { $0.deviceId == deviceId }) {
            return deviceSettings
            
        }
        return nil
    }
    
    func removeDeviceSetting(with id: String) {
        let key = UserDefaultsKey.deviceSettings.rawValue
        if var deviceSettingsArray = storage.object([DeviceSettings].self, with: key) {
            if let index = deviceSettingsArray.firstIndex(where: { $0.deviceId == id }) {
                deviceSettingsArray.remove(at: index)
                storage.set(object: deviceSettingsArray, forKey: key)
            }
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
    
    private func addDeviceSettings(item: DeviceSettings) {
        let key = UserDefaultsKey.deviceSettings.rawValue
        if var deviceSettingsArray = storage.object([DeviceSettings].self, with: key) {
            deviceSettingsArray.append(item)
            storage.set(object: deviceSettingsArray, forKey: key)
        } else {
            storage.set(object: [item], forKey: key)
        }
    }
    
    private func updateDeviceSettings(item: DeviceSettings) {
        let key = UserDefaultsKey.deviceSettings.rawValue
        if var deviceSettingsArray = storage.object([DeviceSettings].self, with: key) {
            if let deviceSettingsIndex = deviceSettingsArray.firstIndex(where: { $0.deviceId == item.deviceId }) {
                deviceSettingsArray[deviceSettingsIndex] = item
                storage.set(object: deviceSettingsArray, forKey: key)
            }
        }
    }
}

