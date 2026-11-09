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
    
    override var deviceServiceName: String {
        "Running Sensor"
    }
    
    override class var getServiceUUID: String {
        GattAttributes.SERVICE_RUNNING_SPEED_AND_CADENCE
    }
    
    override var getServiceConnectedImage: UIImage? {
        .widgetSensorSpeed
    }
    
    override var getServiceDisconnectedImage: UIImage? {
        .icCustomSensorSpeedOutlined
    }
    
    override func dataFields(appMode: OAApplicationMode?) -> [[String: String]]? {
        if let sensor = sensors.first(where: { $0 is BLERunningSensor }) as? BLERunningSensor {
            var result = [[String: String]]()
            if let lastRunningCadenceData = sensor.lastRunningCadenceData {
                result.append([localizedString("external_device_characteristic_cadence"): String(lastRunningCadenceData.cadence) + " " + localizedString("revolutions_per_minute_unit")])
            }
            if let lastRunningSpeedData = sensor.lastRunningSpeedData {
                if let speed = OAOsmAndFormatter.getFormattedSpeed(Float(lastRunningSpeedData.speed.value), mode: appMode) {
                    result.append([localizedString("external_device_characteristic_speed"): String(speed)])
                }
            }
            if let lastRunningDistanceData = sensor.lastRunningDistanceData {
                let distanceMeters = lastRunningDistanceData.totalDistance.value / 10
                if let distance = OAOsmAndFormatter.getFormattedDistance(Float(distanceMeters), mode: appMode, with: OsmAndFormatterParams.noTrailingZeros) {
                    result.append([localizedString("external_device_characteristic_total_distance"): String(distance)])
                }
            }
            if let lastRunningStrideLengthData = sensor.lastRunningStrideLengthData {
                let strideLengthMeters = lastRunningStrideLengthData.strideLength.value / 100
                if let strideLength = OAOsmAndFormatter.getFormattedDistance(Float(strideLengthMeters), mode: appMode, with: OsmAndFormatterParams.noTrailingZeros) {
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
    
    override func update(with characteristic: CBCharacteristic, result: @escaping (Result<Void, Error>) -> Void) {
        sensors.forEach { $0.update(with: characteristic, result: result) }
    }
}
