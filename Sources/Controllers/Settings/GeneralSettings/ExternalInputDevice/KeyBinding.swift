//
//  KeyBinding.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 03.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyBinding {
    private let keyCode: UIKeyboardHIDUsage
    private let commandId: String
    private var cachedCommand: KeyEventCommand?
    
    init(keyCode: UIKeyboardHIDUsage, commandId: String) {
        self.keyCode = keyCode
        self.commandId = commandId
    }
    
    convenience init(json: [String: Any]) throws {
        guard let keyCode = json["keycode"] as? UIKeyboardHIDUsage,
              let commandId = json["commandId"] as? String else {
            throw NSError(domain: "KeyBinding", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing keycode/commandId"])
        }
        self.init(keyCode: keyCode, commandId: commandId)
    }
    
    func getCommand() -> KeyEventCommand? {
        if cachedCommand == nil {
            cachedCommand = KeyEventCommandsCache.getOrCreateCommand(commandId)
        }
        return cachedCommand
    }
    
    func getCommandId() -> String {
        commandId
    }
    
    func getCommandTitle() -> String? {
        getCommand()?.toHumanString()
    }
    
    func getKeySymbol() -> String {
        KeySymbolMapper.getKeySymbol(for: getKeyCode())
    }
    
    func getKeyCode() -> UIKeyboardHIDUsage {
        keyCode
    }
    
    func toJson() -> [String: Any] {
        [
            "keycode": keyCode,
            "commandId": commandId
        ]
    }
}
