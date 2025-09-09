//
//  InputDevicesCollection.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 05.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class InputDevicesCollection {
    private let appMode: OAApplicationMode
    private var customDevices: [InputDeviceProfile]
    private let defaultDevices: [InputDeviceProfile]
    private var cachedDevices: [String: InputDeviceProfile] = [:]

    init(appMode: OAApplicationMode, customDevices: [InputDeviceProfile]) {
        self.appMode = appMode
        self.customDevices = customDevices
        self.defaultDevices = DefaultInputDevices.values()
        syncCachedDevices()
    }

    func hasDeviceNameDuplicate(of newName: String) -> Bool {
        for device in getAllDevices() {
            if device.toHumanString().trimmingCharacters(in: .whitespaces) ==
               newName.trimmingCharacters(in: .whitespaces) {
                return true
            }
        }
        return false
    }

    func getAppMode() -> OAApplicationMode {
        appMode
    }

    func getAllDevices() -> [InputDeviceProfile] {
        defaultDevices + customDevices
    }

    func getCustomDevices() -> [InputDeviceProfile] {
        customDevices
    }

    func addCustomDevice(_ device: InputDeviceProfile) {
        customDevices.append(device)
        syncCachedDevices()
    }

    func removeCustomDevice(_ deviceId: String) {
        guard let device = getDeviceById(deviceId) else { return }
        customDevices.removeAll { $0.getId() == device.getId() }
        syncCachedDevices()
    }

    func getCustomDeviceById(_ deviceId: String) -> CustomInputDeviceProfile? {
        getDeviceById(deviceId) as? CustomInputDeviceProfile
    }

    func getDeviceById(_ deviceId: String) -> InputDeviceProfile? {
        cachedDevices[deviceId]
    }

    private func syncCachedDevices() {
        var newCached: [String: InputDeviceProfile] = [:]
        for device in getAllDevices() {
            newCached[device.getId()] = device
        }
        cachedDevices = newCached
    }
}
