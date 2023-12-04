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
        if let sensor = sensors.first(where: { $0 is BLERunningSensor }) as? BLERunningSensor {
            var result = [[String: String]]()
            if let lastRunningCadenceData = sensor.lastRunningCadenceData {
                result.append([localizedString("external_device_characteristic_cadence"): String(lastRunningCadenceData.cadence)])
            }
            if let lastRunningSpeedData = sensor.lastRunningSpeedData {
                if let speed = OAOsmAndFormatter.getFormattedSpeed(Float(lastRunningSpeedData.speed.value)) {
                    result.append([localizedString("external_device_characteristic_speed"): String(speed)])
                }
            }
            if let lastRunningDistanceData = sensor.lastRunningDistanceData {
                let distanceMeters = lastRunningDistanceData.totalDistance.value / 10
                if let distance = OAOsmAndFormatter.getFormattedDistance(Float(distanceMeters), forceTrailingZeroes: false) {
                    result.append([localizedString("external_device_characteristic_total_distance"): String(distance)])
                }
            }
            if let lastRunningStrideLengthData = sensor.lastRunningStrideLengthData {
                let strideLengthMeters = lastRunningStrideLengthData.strideLength.value / 100
               
                if let strideLength = OAOsmAndFormatter.getFormattedDistance(Float(strideLengthMeters), forceTrailingZeroes: false) {
                    result.append([localizedString("external_device_characteristic_stride_length"): String(strideLength)])
                }
            }
            return result.isEmpty ? nil : result
        }
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
