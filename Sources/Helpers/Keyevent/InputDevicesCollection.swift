//
//  InputDevicesCollection.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 05.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class InputDevicesCollection {
    private let appMode: OAApplicationMode
    private let defaultDevices: [InputDeviceProfile]
    private var customDevices: [InputDeviceProfile]
    private var cachedDevices: [String: InputDeviceProfile] = [:]

    init(appMode: OAApplicationMode, customDevices: [InputDeviceProfile]) {
        self.appMode = appMode
        self.customDevices = customDevices
        defaultDevices = DefaultInputDevices.values()
        syncCachedDevices()
    }

    func hasDeviceNameDuplicate(of newName: String) -> Bool {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        return allDevices().contains { $0.toHumanString().trimmingCharacters(in: .whitespaces) == trimmedName }
    }

    func currentAppMode() -> OAApplicationMode {
        appMode
    }

    func allDevices() -> [InputDeviceProfile] {
        defaultDevices + customDevices
    }

    func storedCustomDevices() -> [InputDeviceProfile] {
        customDevices
    }

    func addCustomDevice(_ device: InputDeviceProfile) {
        customDevices.append(device)
        syncCachedDevices()
    }

    func removeCustomDevice(_ deviceId: String) {
        guard let device = deviceById(deviceId) else { return }
        customDevices.removeAll { $0.id() == device.id() }
        syncCachedDevices()
    }

    func customDeviceById(_ deviceId: String) -> CustomInputDeviceProfile? {
        deviceById(deviceId) as? CustomInputDeviceProfile
    }

    func deviceById(_ deviceId: String) -> InputDeviceProfile? {
        cachedDevices[deviceId]
    }

    private func syncCachedDevices() {
        var newCached: [String: InputDeviceProfile] = [:]
        allDevices().forEach { newCached[$0.id()] = $0 }
        cachedDevices = newCached
    }
}
