//
//  InputDeviceProfile.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 02.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
class InputDeviceProfile: NSObject {
    var settings: OAAppSettings
    var keyBindings: [KeyBinding] = []
    var keyBindingsCache: [UIKeyboardHIDUsage: KeyBinding] = [:]
    
    override init() {
        settings = OAAppSettings.sharedManager()
    }
    
    func getKeyBindings() -> [KeyBinding] {
        keyBindings
    }
    
    func setKeyBindings(_ keyBindings: [KeyBinding]) {
        self.keyBindings = keyBindings
        syncKeyBindingsCache()
    }
    
    func syncKeyBindingsCache() {
        var newQuickCache: [UIKeyboardHIDUsage: KeyBinding] = [:]
        for keyBinding in keyBindings {
            newQuickCache[keyBinding.getKeyCode()] = keyBinding
        }
        self.keyBindingsCache = newQuickCache
    }
    
    func getId() -> String? {
        nil
    }
    
    func isCustom() -> Bool {
        false
    }
    
    func toHumanString() -> String? {
        nil
    }
}
