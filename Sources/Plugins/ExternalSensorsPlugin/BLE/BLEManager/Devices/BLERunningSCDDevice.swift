//
//  BLERunningSCDDevice.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 01.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import CoreBluetooth

final class BLERunningSCDDevice: Device {
    
    var name: String {
        "Running Sensor"
    }
    
    override class var getServiceUUID: String {
        GattAttributes.SERVICE_RUNNING_SPEED_AND_CADENCE
    }
    
    override var getServiceConnectedImage: UIImage {
        UIImage(named: "widget_sensor_speed")!
    }
    
    override var getDataFields: [[String: String]]? {
//        if let sensor = sensors.first(where: { $0 is BLEBikeSensor }) as? BLEBikeSensor {
//            var result = [[String: String]]()
//            if let lastBikeSpeedDistanceData = sensor.lastBikeSpeedDistanceData {
//                let speed = OAOsmAndFormatter.getFormattedSpeed(Float(lastBikeSpeedDistanceData.speed.value))
//                let distance = OAOsmAndFormatter.getFormattedDistance(Float(lastBikeSpeedDistanceData.totalTravelDistance.value), forceTrailingZeroes: false)
//                debugPrint("speed: \(speed ?? "")")
//                debugPrint("distance: \(distance ?? "")")
//                
//                result.append([localizedString("external_device_characteristic_speed"): String(speed!)])
//                result.append([localizedString("external_device_characteristic_total_distance"): String(distance!)])
//            }
//            if let lastBikeCadenceData = sensor.lastBikeCadenceData {
//                result.append([localizedString("external_device_characteristic_cadence"): String(lastBikeCadenceData.cadence)])
//            }
//            return result.isEmpty ? nil : result
//        }
        return nil
    }

    
    init() {
        super.init(deviceType: .BLE_RUNNING_SCDS)
        sensors.append(BLERunningSensor(device: self, sensorId: "running"))
    }
    
    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        [.bicycleSpeed, .bicycleCadence, .bicycleDistance]
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        sensors.forEach { $0.update(with: characteristic, result: result) }
    }
}
