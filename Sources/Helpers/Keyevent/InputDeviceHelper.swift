//
//  InputDeviceHelper.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 03.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class InputDeviceHelper: NSObject {
    static let shared = InputDeviceHelper()
    static let none: InputDeviceProfile = NoneDeviceProfile()
    static let keyboard: InputDeviceProfile = KeyboardDeviceProfile()
    static let wunderlinq: InputDeviceProfile = WunderLINQDeviceProfile()
    
    private static let customPrefix = "custom_"
    
    private let settings: OAAppSettings
    private lazy var defaultDevices: [InputDeviceProfile] = [Self.none, Self.keyboard, Self.wunderlinq]
    private var customDevices: [InputDeviceProfile] = []
    private var cachedDevices: [String: InputDeviceProfile] = [:]
    
    override init() {
        settings = OAAppSettings.sharedManager()
        super.init()
        customDevices = loadCustomDevices()
        for device in getAvailableDevices() {
            guard let id = device.getId() else { continue }
            cachedDevices[id] = device
        }
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
    
    private static func readFromJson(_ json: [String: Any]) throws -> [InputDeviceProfile] {
        guard let items = json["items"] as? [[String: Any]] else {
            return []
        }
        
        var result: [InputDeviceProfile] = []
        for item in items {
            do {
                let device = try CustomInputDeviceProfile(item)
                result.append(device)
            } catch {
                print("Error while reading a custom device from JSON: \(error)")
            }
        }
        return result
    }
    
    private static func writeToJson(_ json: inout [String: Any], customDevices: [InputDeviceProfile]) throws {
        var items: [[String: Any]] = []
        for device in customDevices {
            if let custom = device as? CustomInputDeviceProfile {
                items.append(custom.toJson())
            }
        }
        json["items"] = items
    }
    
    func getAvailableDevices() -> [InputDeviceProfile] {
        defaultDevices + customDevices
    }
    
    func getCustomDevices() -> [InputDeviceProfile] {
        customDevices
    }
    
    func selectInputDevice(with appMode: OAApplicationMode, deviceId: String) {
        settings.settingExternalInputDevice.set(deviceId, mode: appMode)
    }
    
    func createAndSaveCustomDevice(with newName: String) {
        saveCustomDevice(makeCustomDevice(with: newName))
    }
    
    func createAndSaveDeviceDuplicate(of device: InputDeviceProfile) {
        let newDevice = makeCustomDeviceDuplicate(of: device)
        saveCustomDevice(newDevice)
    }
    
    func renameCustomDevice(_ device: CustomInputDeviceProfile, with newName: String) {
        device.setCustomName(newName)
        syncSettings()
    }
    
    func removeCustomDevice(with deviceId: String) {
        guard let device = cachedDevices.removeValue(forKey: deviceId) else { return }
        customDevices.removeAll(where: { $0 == device })
        cachedDevices.removeValue(forKey: deviceId)
        syncSettings()
        resetSelectedDeviceIfNeeded()
    }
    
    func resetSelectedDeviceIfNeeded() {
        OAApplicationMode.allPossibleValues().forEach(resetSelectedDeviceIfNeeded)
    }

    func resetSelectedDeviceIfNeeded(with appMode: OAApplicationMode) {
        let device = getSelectedDevice(with: appMode)
        if device == nil {
            settings.settingExternalInputDevice.resetMode(toDefault: appMode)
        }
    }
    
    func updateKeyBinding(deviceId: String,
                          commandId: String,
                          oldKeyCode: Int,
                          newKeyCode: Int) {
        // TODO
    }
    
//    public void updateKeyBinding(@NonNull String deviceId,
//                                     @NonNull String commandId,
//                                     int oldKeyCode, int newKeyCode) {
//            InputDeviceProfile device = getDeviceById(deviceId);
//            if (device == null) {
//                return;
//            }
//            if (newKeyCode == KeyEvent.KEYCODE_UNKNOWN) {
//                device.removeKeyBinding(oldKeyCode);
//            } else if (oldKeyCode == KeyEvent.KEYCODE_UNKNOWN) {
//                device.addKeyBinding(newKeyCode, commandId);
//            } else {
//                device.updateKeyBinding(oldKeyCode, newKeyCode, commandId);
//            }
//            syncSettings();
//        }
    
    func isSelectedDevice(with appMode: OAApplicationMode, deviceId: String) -> Bool {
        guard let selectedDeviceId = getSelectedDeviceId(with: appMode) else { return false }
        return selectedDeviceId == deviceId
    }

    func isCustomDevice(_ device: InputDeviceProfile) -> Bool {
        guard let id = device.getId() else { return false }
        return id.starts(with: Self.customPrefix)
    }
    
    func getDeviceById(_ deviceId: String) -> InputDeviceProfile? {
        cachedDevices[deviceId]
    }
    
    func getEnabledDevice() -> InputDeviceProfile? {
        getEnabledDevice(with: settings.applicationMode.get())
    }
    
    func getEnabledDevice(with appMode: OAApplicationMode) -> InputDeviceProfile? {
        getSelectedDevice(with: appMode)
    }

    func getSelectedDevice(with appMode: OAApplicationMode) -> InputDeviceProfile? {
        guard let id = getSelectedDeviceId(with: appMode) else { return nil }
        return cachedDevices[id]
    }

    func getSelectedDeviceId(with appMode: OAApplicationMode) -> String? {
        settings.settingExternalInputDevice.get(appMode)
    }
    
    func hasNameDuplicate(of newName: String) -> Bool {
        for device in getAvailableDevices() {
            if device.toHumanString()?.trimmingCharacters(in: .whitespaces) ==
                newName.trimmingCharacters(in: .whitespaces) {
                return true
            }
        }
        return false
    }
    
    func syncSettings() {
        var json = [String: Any]()
        do {
            try Self.writeToJson(&json, customDevices: customDevices);
            let jsonString = try String(data: JSONSerialization.data(withJSONObject: json, options: []), encoding: .utf8) ?? "{}"
            settings.settingCustomExternalInputDevice.set(jsonString)
        } catch {
            print("Error when writing custom devices to JSON: \(error)")
        }
    }
    
    func isCustomDevicesEmpty() -> Bool {
        customDevices.isEmpty
    }
    
    private func makeCustomDeviceDuplicate(of device: InputDeviceProfile) -> InputDeviceProfile {
        let prevName = device.toHumanString()
        let uniqueName = makeUniqueName(with: prevName)
        return makeCustomDevice(with: uniqueName, baseDevice: device)
    }
    
    private func makeUniqueName(with oldName: String?) -> String {
        guard let oldName else { return "" }
        return Self.makeUniqueName(oldName, checkName: { newName in !hasNameDuplicate(of: newName) })
    }
    
    private func makeCustomDevice(with newName: String) -> InputDeviceProfile {
        makeCustomDevice(with: newName, baseDevice: Self.keyboard)
    }
    
    private func makeCustomDevice(with newName: String, baseDevice: InputDeviceProfile) -> InputDeviceProfile {
        let uniqueId = Self.customPrefix + String(Int(Date().timeIntervalSince1970 * 1000))
        return makeCustomDevice(with: uniqueId, name: newName, parentDevice: baseDevice)
    }
    
    private func makeCustomDevice(with id: String, name: String, parentDevice: InputDeviceProfile) -> InputDeviceProfile {
        let device: InputDeviceProfile = CustomInputDeviceProfile(customId: id, customName: name, parentDevice: parentDevice)
        return device
    }
    
    private func saveCustomDevice(_ device: InputDeviceProfile) {
        guard let id = device.getId() else { return }
        customDevices.append(device)
        cachedDevices[id] = device
        syncSettings()
    }
    
    private func loadCustomDevices() -> [InputDeviceProfile] {
        let jsonString = settings.settingCustomExternalInputDevice.get()
        do {
            if let data = jsonString?.data(using: .utf8),
               let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return try Self.readFromJson(jsonObject)
            }
        } catch {
            print("Error when reading custom devices from JSON: \(error)")
        }
        return []
    }
}
