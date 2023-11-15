//
//  DeviceSettings.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 18.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

class DeviceSettings: Codable {
    var deviceId: String
    var deviceType: DeviceType = .BLE_BATTERY
    var deviceName: String = ""
    var deviceEnabled: Bool
    var additionalParams: [String: String]?
    
    init(deviceId: String,
         deviceType: DeviceType,
         deviceName: String,
         deviceEnabled: Bool = true,
         additionalParams: [String: String]? = nil) {
        self.deviceId = deviceId
        self.deviceType = deviceType
        self.deviceName = deviceName
        self.deviceEnabled = deviceEnabled
        self.additionalParams = additionalParams
    }

    func setDeviceProperty(key: String, value: String) {
        if additionalParams == nil {
            additionalParams = [String: String]()
        }
        additionalParams?[key] = value
    }
}
