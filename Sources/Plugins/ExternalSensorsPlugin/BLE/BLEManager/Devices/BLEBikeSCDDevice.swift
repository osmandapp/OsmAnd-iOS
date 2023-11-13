//
//  BLEBikeSCDDevice.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 24.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import CoreBluetooth

final class BLEBikeSCDDevice: Device {
    
    init() {
        super.init(deviceType: .BLE_BICYCLE_SCD)
        sensors.append(BLEBikeSensor(device: self, sensorId: "bike_scd"))
    }
    
    var name: String {
        "Bike Sensor"
    }
    
    override class var getServiceUUID: String {
        GattAttributes.SERVICE_CYCLING_SPEED_AND_CADENCE
    }
    
    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        [.bicycleSpeed, .bicycleCadence, .bicycleDistance]
    }
    
    override var getServiceConnectedImage: UIImage {
        UIImage(named: "widget_sensor_bicycle_power")!
    }
    
    override var getDataFields: [String : String]? {
        if let sensor = sensors.first(where: { $0 is BLEBikeSensor }) as? BLEBikeSensor {
            var dic = [String: String]()
            if let lastBikeSpeedDistanceData = sensor.lastBikeSpeedDistanceData {
                dic[localizedString("external_device_characteristic_speed")] = String(lastBikeSpeedDistanceData.speed)
            }
            if let lastBikeCadenceData = sensor.lastBikeCadenceData {
                dic[localizedString("external_device_characteristic_cadence")] = String(lastBikeCadenceData.cadence)
            }

            return dic.isEmpty ? nil : dic
        }
        return nil
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        sensors.forEach { $0.update(with: characteristic, result: result)}
    }
}

