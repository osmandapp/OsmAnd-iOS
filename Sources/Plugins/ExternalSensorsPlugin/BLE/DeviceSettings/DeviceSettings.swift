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
   // var additionalParams: Any?
    
    init(deviceId: String,
         deviceType: DeviceType,
         deviceName: String,
         deviceEnabled: Bool = true) {
        self.deviceId = deviceId
        self.deviceType = deviceType
        self.deviceName = deviceName
        self.deviceEnabled = deviceEnabled
      //  self.additionalParams = additionalParams
    }

//    func setDeviceProperty(property: DeviceChangeableProperties, value: String) {
//        if (additionalParams.containsKey(property)) {
//            additionalParams[property] = value
//        }
//    }
}
