//
//  KeyAssignment.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyAssignment {
    private static var idCounter = 0
    
    private var id: String?
    private var commandId: String?
    private var customName: String?
    private var action: OAQuickAction?
    private var keyCodes: [UIKeyboardHIDUsage] = []
    
    init(action: OAQuickAction?, keyCodes: [UIKeyboardHIDUsage]) {
        self.id = Self.generateUniqueId()
        self.action = action
        self.keyCodes = keyCodes
    }
    
    init(original: KeyAssignment) {
        self.id = original.id
        self.action = original.action
        self.commandId = original.commandId
        self.customName = original.customName
        self.keyCodes = original.keyCodes
    }
    
    init(action: OAQuickAction) {
        self.action = action
    }
    
    init(keyCodes: [UIKeyboardHIDUsage]) {
        self.keyCodes = keyCodes
    }
    
    init(jsonObject: [String: Any]) {
        if let providedId = jsonObject["id"] as? String {
            self.id = providedId
        } else {
            self.id = Self.generateUniqueId()
        }
        
        self.customName = jsonObject["customName"] as? String
        
        if let actionArray = jsonObject["action"] as? [[String: Any]] {
            if let data = try? JSONSerialization.data(withJSONObject: actionArray, options: []),
               let actions = try? OAMapButtonsHelper.sharedInstance().getSerializer().deserialize(data) {
                self.action = actions.first
            } else {
                self.action = nil
            }
        } else if let cmdId = jsonObject["commandId"] as? String {
            self.commandId = cmdId
            self.action = CommandToActionConverter.createQuickAction(with: cmdId)
        } else {
            self.action = nil
        }
        
        var collected = [UIKeyboardHIDUsage]()
        if let keyCodesArray = jsonObject["keycodes"] as? [[String: Any]] {
            for item in keyCodesArray {
                if let keyCodeRawValue = item["keycode"] as? CFIndex, let keyCode = UIKeyboardHIDUsage(rawValue: keyCodeRawValue) {
                    collected.append(keyCode)
                }
            }
        } else if let singleRawValue = jsonObject["keycode"] as? CFIndex, let single = UIKeyboardHIDUsage(rawValue: singleRawValue) {
            collected.append(single)
        }
        self.keyCodes = collected
    }
    
    convenience init(commandId: String, keyCodes: [UIKeyboardHIDUsage]) {
        self.init(action: CommandToActionConverter.createQuickAction(with: commandId), keyCodes: keyCodes)
        self.commandId = commandId
    }
    
    static func == (lhs: KeyAssignment, rhs: KeyAssignment) -> Bool {
        lhs.id == rhs.id
    }
    
    private static func generateUniqueId() -> String {
        idCounter += 1
        return "key_assignment_\(Date().timeIntervalSince1970 * 1000)_\(idCounter)"
    }
    
    func setAction(_ action: OAQuickAction) {
        self.action = action
    }
    
    func setKeyCodes(_ keyCodes: [UIKeyboardHIDUsage]) {
        self.keyCodes = keyCodes
    }
    
    func setCustomName(_ customName: String) {
        self.customName = customName
    }
    
    func removeKeyCode(_ keyCode: UIKeyboardHIDUsage) {
        guard let idx = keyCodes.firstIndex(of: keyCode) else { return }
        keyCodes.remove(at: idx)
    }
    
    func getId() -> String? {
        id
    }
    
    func getName() -> String? {
        customName ?? getDefaultName()
    }
    
    func getAction() -> OAQuickAction? {
        action
    }
    
    func hasKeyCodes() -> Bool {
        !keyCodes.isEmpty
    }
    
    func hasRequiredParameters() -> Bool {
        hasKeyCodes() && action != nil
    }
    
    func getKeyCodes() -> [UIKeyboardHIDUsage] {
        keyCodes
    }
    
    func getIcon() -> String? {
        guard let action else { return "ic_action_info_outlined" }
        return action.getIconResName()
    }
    
    func toJson() -> [String: Any] {
        var obj: [String: Any] = [:]
        obj["id"] = id
        if let customName {
            obj["customName"] = customName
        }
        
        if let action {
            if let data = try? OAMapButtonsHelper.sharedInstance().getSerializer().serialize([action]),
               let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                obj["action"] = arr
            }
        }
        
        if let commandId {
            obj["commandId"] = commandId
        }
        
        if !keyCodes.isEmpty {
            let arr = keyCodes.map { ["keycode": $0.rawValue] }
            obj["keycodes"] = arr
        }
        return obj
    }
    
    private func getDefaultName() -> String? {
        action?.getExtendedName() ?? commandId
    }
}
