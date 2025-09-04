//
//  KeyboardDeviceProfile.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 02.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class KeyboardDeviceProfile: PredefinedInputDeviceProfile {
    static let deviceId = "keyboard"
    
    override func getId() -> String {
        Self.deviceId
    }
    
    override func toHumanString() -> String {
        localizedString("sett_generic_ext_input")
    }
}
