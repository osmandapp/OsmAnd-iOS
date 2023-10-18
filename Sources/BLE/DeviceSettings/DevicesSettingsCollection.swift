//
//  DevicesSettingsCollection.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class DevicesSettingsCollection {

    private static DEVICES_SETTINGS_PREF_ID = "external_devices_settings"

    private final CommonPreference<String> preference;
    private final Gson gson;
    private final Map<String, DeviceSettings> settings = new HashMap<>();
    private List<DevicePreferencesListener> listeners = new ArrayList<>();


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

//    public void addListener(@NonNull DevicePreferencesListener listener) {
//        if (!listeners.contains(listener)) {
//            List<DevicePreferencesListener> newListeners = new ArrayList<>(listeners);
//            newListeners.add(listener);
//            listeners = newListeners;
//        }
//    }
//
//    public void removeListener(@NonNull DevicePreferencesListener listener) {
//        if (listeners.contains(listener)) {
//            List<DevicePreferencesListener> newListeners = new ArrayList<>(listeners);
//            newListeners.remove(listener);
//            listeners = newListeners;
//        }
//    }

//    @NonNull
//    public Set<String> getDeviceIds() {
//        synchronized (settings) {
//            return new HashSet<>(settings.keySet());
//        }
//    }

    func getDeviceSettings(deviceId: String) -> DeviceSettings? {
        let deviceSettings = settings.get(deviceId)
        return deviceSettings != null ? createDeviceSettings(deviceSettings) : null;
    }

//    private DeviceSettings createDeviceSettings(@NonNull DeviceSettings settings) {
//        switch (settings.getDeviceType()) {
//            case ANT_BICYCLE_SD:
//            case BLE_BICYCLE_SCD:
//                return new WheelDeviceSettings(settings);
//            default:
//                return new DeviceSettings(settings);
//        }
//    }

    static func createDeviceSettings(deviceId: String, deviceType: DeviceType, name: String, deviceEnabled: Bool) -> DeviceSettings {
        switch deviceType {
        case .BLE_BICYCLE_SCD:
            return WheelDeviceSettings(deviceId: deviceId, deviceType: deviceType, deviceName: name, deviceEnabled: deviceEnabled)
        default:
            return DeviceSettings(deviceId: deviceId, deviceType: deviceType, deviceName: name, deviceEnabled: deviceEnabled)
        }
    }

//    public void setDeviceSettings(
//            @NonNull String deviceId,
//            @Nullable DeviceSettings deviceSettings) {
//        setDeviceSettings(deviceId, deviceSettings, true);
//    }
//
//    public void setDeviceSettings(
//            @NonNull String deviceId,
//            @Nullable DeviceSettings deviceSettings,
//            boolean write) {
//        boolean stateChanged;
//        synchronized (settings) {
//            if (deviceSettings == null) {
//                settings.remove(deviceId);
//                stateChanged = true;
//            } else {
//                DeviceSettings prevSettings = settings.get(deviceId);
//                settings.put(deviceId, deviceSettings);
//                stateChanged = prevSettings != null && prevSettings.getDeviceEnabled() != deviceSettings.getDeviceEnabled();
//            }
//            if (write) {
//                writeSettings();
//            }
//        }
//        if (stateChanged) {
//            fireDeviceStateChangedEvent(deviceId, deviceSettings != null && deviceSettings.getDeviceEnabled());
//        }
//    }
//
//    private void fireDeviceStateChangedEvent(@NonNull String deviceId, boolean enabled) {
//        for (DevicePreferencesListener listener : listeners) {
//            if (enabled) {
//                listener.onDeviceEnabled(deviceId);
//            } else {
//                listener.onDeviceDisabled(deviceId);
//            }
//        }
//    }
//
//    private void readSettings() {
//        String settingsJson = preference.get();
//        if (!Algorithms.isEmpty(settingsJson)) {
//            Map<String, DeviceSettings> settings = gson.fromJson(settingsJson,
//                    new TypeToken<HashMap<String, DeviceSettings>>() {
//                    }.getType());
//            if (settings != null) {
//                this.settings.clear();
//                this.settings.putAll(settings);
//            }
//        }
//    }
//
//    private void writeSettings() {
//        String json = gson.toJson(settings,
//                new TypeToken<HashMap<String, DeviceSettings>>() {
//                }.getType());
//        preference.set(json);
//    }
}

