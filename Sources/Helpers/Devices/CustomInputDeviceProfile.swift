//
//  CustomInputDeviceProfile.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 03.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class CustomInputDeviceProfile: InputDeviceProfile {
    private let customId: String
    private var customName: String
    
    init(customId: String, customName: String, parentDevice: InputDeviceProfile) {
        self.customId = customId
        self.customName = customName
        super.init()
        setKeyBindings(parentDevice.getKeyBindings());
    }
    
    init(_ object: [String: Any]) throws {
        guard let id = object["id"] as? String,
              let name = object["name"] as? String else {
            throw NSError(domain: "CustomInputDeviceProfile", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing id or name"])
        }
        self.customId = id
        self.customName = name
        super.init()
        
        var keyBindings: [KeyBinding] = []
        if let jsonArray = object["keybindings"] as? [[String: Any]] {
            for item in jsonArray {
                keyBindings.append(try KeyBinding(json: item))
            }
        }
        setKeyBindings(keyBindings)
    }
    
    override func getId() -> String {
        customId
    }
    
    override func toHumanString() -> String {
        customName
    }
    
    func setCustomName(_ customName: String) {
        self.customName = customName
    }
    
    func toJson() -> [String: Any] {
        var jsonObject: [String: Any] = [:]
        jsonObject["id"] = customId
        jsonObject["name"] = customName
        
        var jsonArray: [[String: Any]] = []
        for keyBinding in getKeyBindings() {
            jsonArray.append(keyBinding.toJson())
        }
        jsonObject["keybindings"] = jsonArray
        
        return jsonObject
    }
}
