//
//  NoneDeviceProfile.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 03.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class NoneDeviceProfile: PredefinedInputDeviceProfile {
    static let deviceId = ""
    
    override func getId() -> String {
        Self.deviceId
    }
    
    override func toHumanString() -> String {
        localizedString("shared_string_none")
    }
}
