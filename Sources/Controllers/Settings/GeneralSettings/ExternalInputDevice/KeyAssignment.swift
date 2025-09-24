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
        id = Self.generateUniqueId()
        self.action = action
        self.keyCodes = keyCodes
    }
    
    init(original: KeyAssignment) {
        id = original.id
        action = original.action
        commandId = original.commandId
        customName = original.customName
        keyCodes = original.keyCodes
    }
    
    init(jsonObject: [String: Any]) {
        if let providedId = jsonObject["id"] as? String {
            id = providedId
        } else {
            id = Self.generateUniqueId()
        }
        
        customName = jsonObject["customName"] as? String
        
        if let actionArray = jsonObject["action"] as? [[String: Any]] {
            if let data = try? JSONSerialization.data(withJSONObject: actionArray, options: []),
               let actions = try? OAMapButtonsHelper.sharedInstance().getSerializer().deserialize(data) {
                action = actions.first
            } else {
                action = nil
            }
        } else if let commandId = jsonObject["commandId"] as? String {
            self.commandId = commandId
            action = CommandToActionConverter.createQuickAction(with: commandId)
        } else {
            action = nil
        }
        
        var collected = [UIKeyboardHIDUsage]()
        if let keyCodesArray = jsonObject["keycodes"] as? [[String: Any]] {
            for item in keyCodesArray {
                if let keyCodeRawValue = item["keycode"] as? CFIndex,
                   let keyEvent = KeyEvent(rawValue: keyCodeRawValue),
                   let keyCode = KeyEventMapper.keyEventToKeyboardHIDUsage(keyEvent) {
                    collected.append(keyCode)
                }
            }
        } else if let singleRawValue = jsonObject["keycode"] as? CFIndex,
                  let keyEvent = KeyEvent(rawValue: singleRawValue),
                  let single = KeyEventMapper.keyEventToKeyboardHIDUsage(keyEvent) {
            collected.append(single)
        }
        keyCodes = collected
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
    
    func storedId() -> String? {
        id
    }
    
    func name() -> String? {
        customName ?? defaultName()
    }
    
    func storedAction() -> OAQuickAction? {
        action
    }
    
    func hasKeyCodes() -> Bool {
        !keyCodes.isEmpty
    }
    
    func hasRequiredParameters() -> Bool {
        hasKeyCodes() && action != nil
    }
    
    func storedKeyCodes() -> [UIKeyboardHIDUsage] {
        keyCodes
    }
    
    func icon() -> String? {
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
            let arr = keyCodes.map { ["keycode": KeyEventMapper.keyboardHIDUsageToKeyEvent($0).rawValue] }
            obj["keycodes"] = arr
        }
        return obj
    }
    
    private func defaultName() -> String? {
        action?.getExtendedName() ?? commandId
    }
}
