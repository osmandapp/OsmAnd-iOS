//
//  InputDevicesHelper.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 03.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class InputDevicesHelper: NSObject {
    static let shared = InputDevicesHelper()
    static let none: InputDeviceProfile = NoneDeviceProfile()
    static let keyboard: InputDeviceProfile = KeyboardDeviceProfile()
    static let wunderlinq: InputDeviceProfile = WunderLINQDeviceProfile()
    
    private static let functionalityPurposeId = 0
    private static let customizationPurposeId = 1
    private static let customDevicePrefix = "custom_"
    
    private let settings: OAAppSettings
    private var cachedDevicesCollections: [Int: InputDevicesCollection] = [:]
    
    override init() {
        settings = OAAppSettings.sharedManager()
        super.init()
    }
    
    static func makeUniqueName(_ oldName: String, checkName: (String) -> Bool) -> String {
        let chars = Array(oldName)
        var suffix = 0
        var i = chars.count - 1

        repeat {
            if i < 0 { break }
            let ch = chars[i]
            if ch == " " || ch == "-" {
                break
            }
            let tail = String(chars[i..<chars.count])
            if let parsed = Int(tail) {
                suffix = parsed
            } else {
                break
            }
            i -= 1
        } while i >= 0

        let divider = (suffix == 0) ? " " : ""
        var newName: String

        repeat {
            suffix += 1
            let prefix = String(chars.prefix(max(0, i + 1)))
            newName = prefix + divider + String(suffix)
        } while !checkName(newName)

        return newName
    }
    
    func selectInputDevice(with appMode: OAApplicationMode, deviceId: String) {
        settings.settingExternalInputDevice.set(deviceId, mode: appMode)
        reloadFunctionalityCollection(with: appMode)
    }
    
    func createAndSaveCustomDevice(with appMode: OAApplicationMode, newDeviceName: String) {
        let devicesCollection = customizationCollection(with: appMode)
        saveCustomDevice(makeCustomDevice(with: newDeviceName), in: devicesCollection)
    }

    func createAndSaveDeviceDuplicate(with appMode: OAApplicationMode, device: InputDeviceProfile) {
        let devicesCollection = customizationCollection(with: appMode)
        saveCustomDevice(makeCustomDeviceDuplicate(of: device, in: devicesCollection), in: devicesCollection)
    }
    
    func renameCustomDevice(with appMode: OAApplicationMode, deviceId: String, newName: String) {
        let devicesCollection = customizationCollection(with: appMode)
        if let device = devicesCollection.deviceById(deviceId) as? CustomInputDeviceProfile {
            device.setCustomName(newName)
            syncSettings(in: devicesCollection)
        }
    }
    
    func removeCustomDevice(with appMode: OAApplicationMode, deviceId: String) {
        let devicesCollection = customizationCollection(with: appMode)
        resetSelectedDeviceIfNeeded(with: appMode, removedDeviceId: deviceId)
        devicesCollection.removeCustomDevice(deviceId)
        syncSettings(in: devicesCollection)
    }
    
    func allDevices(with appMode: OAApplicationMode) -> [InputDeviceProfile] {
        customizationCollection(with: appMode).allDevices()
    }
    
    func functionalityDevice(with appMode: OAApplicationMode) -> InputDeviceProfile {
        selectedDevice(with: Self.functionalityPurposeId, appMode: appMode)
    }
    
    func customDevices(with appMode: OAApplicationMode) -> [InputDeviceProfile] {
        customizationCollection(with: appMode).storedCustomDevices()
    }
    
    func isCustomDevicesEmpty(with appMode: OAApplicationMode) -> Bool {
        customDevices(with: appMode).isEmpty
    }
    
    func selectedDevice(with appMode: OAApplicationMode) -> InputDeviceProfile {
        selectedDevice(with: Self.customizationPurposeId, appMode: appMode)
    }
    
    func deviceById(_ appMode: OAApplicationMode, _ deviceId: String) -> InputDeviceProfile? {
        deviceById(with: Self.customizationPurposeId, appMode: appMode, deviceId: deviceId)
    }
    
    func renameAssignment(with appMode: OAApplicationMode, deviceId: String, assignmentId: String, newName: String) {
        let devicesCollection = customizationCollection(with: appMode)
        if let device = devicesCollection.customDeviceById(deviceId) {
            device.renameAssignment(assignmentId, with: newName)
            syncSettings(in: devicesCollection)
        }
    }

    func addAssignment(with appMode: OAApplicationMode, deviceId: String, assignment: KeyAssignment) {
        let devicesCollection = customizationCollection(with: appMode)
        if let device = devicesCollection.customDeviceById(deviceId) {
            device.addAssignment(assignment)
            syncSettings(in: devicesCollection)
        }
    }

    func updateAssignment(with appMode: OAApplicationMode, deviceId: String, assignmentId: String, action: OAQuickAction, keyCodes: [UIKeyboardHIDUsage]) {
        let devicesCollection = customizationCollection(with: appMode)
        if let device = devicesCollection.customDeviceById(deviceId) {
            device.updateAssignment(assignmentId, action: action, keyCodes: keyCodes)
            syncSettings(in: devicesCollection)
        }
    }
    
    func removeKeyAssignmentCompletely(with appMode: OAApplicationMode, deviceId: String, assignmentId: String) {
        let devicesCollection = customizationCollection(with: appMode)
        if let device = devicesCollection.customDeviceById(deviceId) {
            device.removeKeyAssignmentCompletely(by: assignmentId)
            syncSettings(in: devicesCollection)
        }
    }

    func saveUpdatedAssignmentsList(with appMode: OAApplicationMode, deviceId: String, assignments: [KeyAssignment]) {
        let devicesCollection = customizationCollection(with: appMode)
        if let device = devicesCollection.customDeviceById(deviceId) {
            device.saveUpdatedAssignmentsList(assignments)
            syncSettings(in: devicesCollection)
        }
    }

    func clearAllAssignments(with appMode: OAApplicationMode, deviceId: String) {
        let devicesCollection = customizationCollection(with: appMode)
        if let device = devicesCollection.customDeviceById(deviceId) {
            device.clearAllAssignments()
            syncSettings(in: devicesCollection)
        }
    }
    
    func findAssignment(with appMode: OAApplicationMode, deviceId: String, assignmentId: String) -> KeyAssignment? {
        let device = deviceById(with: Self.customizationPurposeId, appMode: appMode, deviceId: deviceId)
        return device?.findAssignment(by: assignmentId)
    }
    
    private func makeCustomDeviceDuplicate(of device: InputDeviceProfile, in devicesCollection: InputDevicesCollection) -> InputDeviceProfile {
        let prevName = device.toHumanString()
        let uniqueName = makeUniqueName(with: devicesCollection, oldName: prevName)
        return makeCustomDevice(with: uniqueName, baseDevice: device)
    }
    
    private func makeUniqueName(with devicesCollection: InputDevicesCollection, oldName: String) -> String {
        Self.makeUniqueName(oldName, checkName: { newName in !devicesCollection.hasDeviceNameDuplicate(of: newName) })
    }

    private func makeCustomDevice(with newName: String) -> InputDeviceProfile {
        makeCustomDevice(with: newName, baseDevice: Self.keyboard)
    }
    
    private func makeCustomDevice(with newName: String, baseDevice: InputDeviceProfile) -> InputDeviceProfile {
        let uniqueId = Self.customDevicePrefix + String(Int(Date().timeIntervalSince1970 * 1000))
        return makeCustomDevice(with: uniqueId, name: newName, parentDevice: baseDevice)
    }
    
    private func makeCustomDevice(with newDeviceId: String, name: String, parentDevice: InputDeviceProfile) -> InputDeviceProfile {
        CustomInputDeviceProfile(customId: newDeviceId, customName: name, parentDevice: parentDevice)
    }
    
    private func saveCustomDevice(_ device: InputDeviceProfile, in devicesCollection: InputDevicesCollection) {
        devicesCollection.addCustomDevice(device)
        syncSettings(in: devicesCollection)
    }
    
    private func selectedDevice(with cacheId: Int, appMode: OAApplicationMode) -> InputDeviceProfile {
        let id = selectedDeviceId(with: appMode)
        let device = id.flatMap { deviceById(with: cacheId, appMode: appMode, deviceId: $0) }
        return device ?? Self.keyboard
    }
    
    private func selectedDeviceId(with appMode: OAApplicationMode) -> String? {
        settings.settingExternalInputDevice.get(appMode)
    }
    
    private func deviceById(with cacheId: Int, appMode: OAApplicationMode, deviceId: String) -> InputDeviceProfile? {
        inputDevicesCollection(with: cacheId, appMode: appMode).deviceById(deviceId)
    }
    
    private func customizationCollection(with appMode: OAApplicationMode) -> InputDevicesCollection {
        inputDevicesCollection(with: Self.customizationPurposeId, appMode: appMode)
    }

    private func inputDevicesCollection(with cacheId: Int, appMode: OAApplicationMode) -> InputDevicesCollection {
        if let current = cachedDevicesCollections[cacheId],
           current.currentAppMode() == appMode {
            return current
        }
        return reloadInputDevicesCollection(with: cacheId, appMode: appMode)
    }
    
    private func resetSelectedDeviceIfNeeded(with appMode: OAApplicationMode, removedDeviceId: String) {
        let device = selectedDevice(with: appMode)
        if device.id() == removedDeviceId {
            settings.settingExternalInputDevice.resetMode(toDefault: appMode)
        }
    }
    
    @discardableResult
    private func reloadInputDevicesCollection(with cacheId: Int, appMode: OAApplicationMode) -> InputDevicesCollection {
        let collection = InputDevicesCollection(appMode: appMode, customDevices: loadCustomDevices())
        cachedDevicesCollections[cacheId] = collection
        return collection
    }
    
    private func reloadFunctionalityCollection(with appMode: OAApplicationMode) {
        reloadInputDevicesCollection(with: Self.functionalityPurposeId, appMode: appMode)
    }
    
    private func loadCustomDevices() -> [InputDeviceProfile] {
        var devices = readCustomDevices(settings.settingCustomExternalInputDevice.get())
        if mergeLegacyCustomDevices(into: &devices) {
            saveCustomDevices(devices)
        }
        return devices
    }
    
    private func readCustomDevices(_ json: String?) -> [InputDeviceProfile] {
        guard let json, !json.isEmpty else { return [] }
        do {
            if let data = json.data(using: .utf8),
               let jsonObj = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return Self.readFromJson(jsonObj)
            }
        } catch {
            debugPrint("Error while reading custom devices from JSON \(error)")
        }
        return []
    }
    
    private func saveCustomDevices(_ devices: [InputDeviceProfile]) {
        var json: [String: Any] = [:]
        do {
            Self.writeToJson(&json, customDevices: devices)
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            if let str = String(data: data, encoding: .utf8) {
                settings.settingCustomExternalInputDevice.set(str)
            }
        } catch {
            debugPrint("Error while writing custom devices to JSON \(error)")
        }
    }
    
    // Custom devices were stored per profile before they became shared by all profiles.
    // Such per-profile lists still come from the app upgrade, from imported profiles
    // and from Cloud data of older clients, so they are merged into the global list.
    private func mergeLegacyCustomDevices(into devices: inout [InputDeviceProfile]) -> Bool {
        let legacyPreference = settings.settingLegacyCustomExternalInputDevice
        var changed = false
        for appMode in OAApplicationMode.allPossibleValues() where legacyPreference.isSet(for: appMode) {
            let selectedId = settings.settingExternalInputDevice.get(appMode)
            for device in readCustomDevices(legacyPreference.get(appMode)) {
                let mergedId = mergeLegacyDevice(device, into: &devices)
                if device.id() == selectedId && device.id() != mergedId {
                    settings.settingExternalInputDevice.set(mergedId, mode: appMode)
                }
            }
            legacyPreference.resetMode(toDefault: appMode)
            changed = true
        }
        return changed
    }
    
    // Returns id of the device in the global list that now holds this legacy device
    private func mergeLegacyDevice(_ device: InputDeviceProfile, into devices: inout [InputDeviceProfile]) -> String {
        let content = deviceContent(device)
        if let content, let existing = devices.first(where: { deviceContent($0) == content }) {
            return existing.id()
        }
        var merged = device
        let name = device.toHumanString()
        let nameTaken = hasDeviceName(name, in: devices)
        if nameTaken || devices.contains(where: { $0.id() == device.id() }) {
            let uniqueName = nameTaken ? Self.makeUniqueName(name, checkName: { !hasDeviceName($0, in: devices) }) : name
            merged = makeCustomDevice(with: makeUniqueId(in: devices), name: uniqueName, parentDevice: device)
        }
        devices.append(merged)
        return merged.id()
    }
    
    private func deviceContent(_ device: InputDeviceProfile) -> String? {
        guard let custom = device as? CustomInputDeviceProfile else { return nil }
        var json = custom.toJson()
        // A merged copy may get a new id and name, so only the assignments are compared.
        // Quick action ids are generated on every read, and commandId is kept only
        // for assignments read from the old format, so they are not part of the content either
        json.removeValue(forKey: "id")
        json.removeValue(forKey: "name")
        if let assignments = json["assignments"] as? [[String: Any]] {
            json["assignments"] = assignments.map { assignment -> [String: Any] in
                var assignment = assignment
                assignment.removeValue(forKey: "commandId")
                if let actions = assignment["action"] as? [[String: Any]] {
                    assignment["action"] = actions.map { action -> [String: Any] in
                        var action = action
                        action.removeValue(forKey: "id")
                        return action
                    }
                }
                return assignment
            }
        }
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func hasDeviceName(_ name: String, in customDevices: [InputDeviceProfile]) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        return (DefaultInputDevices.values() + customDevices).contains { $0.toHumanString().trimmingCharacters(in: .whitespaces) == trimmedName }
    }
    
    private func makeUniqueId(in devices: [InputDeviceProfile]) -> String {
        var time = Int(Date().timeIntervalSince1970 * 1000)
        while devices.contains(where: { $0.id() == Self.customDevicePrefix + String(time) }) {
            time += 1
        }
        return Self.customDevicePrefix + String(time)
    }
    
    private func syncSettings(in devicesCollection: InputDevicesCollection) {
        saveCustomDevices(devicesCollection.storedCustomDevices())
        // Custom devices are shared by all profiles, so the active device must be reloaded
        // whichever profile was edited
        cachedDevicesCollections.removeValue(forKey: Self.functionalityPurposeId)
    }
    
    private static func readFromJson(_ json: [String: Any]) -> [InputDeviceProfile] {
        guard let arr = json["items"] as? [[String: Any]] else { return [] }
        var res: [InputDeviceProfile] = []
        res.reserveCapacity(arr.count)
        for item in arr {
            do {
                let dev = try CustomInputDeviceProfile(item)
                res.append(dev)
            } catch {
                debugPrint("Error while reading a custom device from JSON \(error)")
            }
        }
        return res
    }
    
    private static func writeToJson(_ json: inout [String: Any], customDevices: [InputDeviceProfile]) {
        var array: [[String: Any]] = []
        array.reserveCapacity(customDevices.count)
        for device in customDevices {
            if let custom = device as? CustomInputDeviceProfile {
                array.append(custom.toJson())
            }
        }
        json["items"] = array
    }
}
