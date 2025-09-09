//
//  DefaultInputDevices.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 05.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class DefaultInputDevices {
    static let none = NoneDeviceProfile()
    static let keyboard = KeyboardDeviceProfile()
    static let wunderlinq = WunderLINQDeviceProfile()
    static var devices: [InputDeviceProfile] = []
    
    static func values() -> [InputDeviceProfile] {
        if devices.count == 0 {
            devices.append(contentsOf: [none, keyboard, wunderlinq])
        }
        return devices
    }
}
