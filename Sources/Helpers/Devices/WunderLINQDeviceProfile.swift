//
//  WunderLINQDeviceProfile.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 02.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class WunderLINQDeviceProfile: PredefinedInputDeviceProfile {
    static let deviceId = "wunderlinq"
    
    override func getId() -> String {
        Self.deviceId
    }
    
    override func toHumanString() -> String {
        localizedString("sett_wunderlinq_ext_input")
    }
}
