//
//  BLEHeartRateDevice.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 12.10.2023.
//

import CoreBluetooth
import UIKit

final class BLEHeartRateDevice: Device {
    
    override var deviceServiceName: String {
        "Heart Rate"
    }
    
    override class var getServiceUUID: String {
        GattAttributes.SERVICE_HEART_RATE
    }
    
    override var getServiceConnectedImage: UIImage? {
        UIImage(named: "widget_sensor_heart_rate")
    }
    
    override var getServiceDisconnectedImage: UIImage? {
        UIImage(named: "ic_custom_sensor_heart_rate_outlined")
    }
    
    override var getDataFields: [[String: String]]? {
        if let sensor = sensors.first(where: { $0 is BLEHeartRateSensor }) as? BLEHeartRateSensor {
            if let lastHeartRateData = sensor.lastHeartRateData {
                return [[localizedString("map_widget_ant_heart_rate"):
                            lastHeartRateData.heartRate == 0
                        ? "-"
                        : String(lastHeartRateData.heartRate) + " " + localizedString("beats_per_minute_short")]]
            } else {
                return [[localizedString("map_widget_ant_heart_rate"): "-"]]
            }
        }
        return nil
    }
    
    init() {
        super.init(deviceType: .BLE_HEART_RATE)
        sensors.append(BLEHeartRateSensor(device: self, sensorId: "heart_rate"))
    }
    
    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        [.heartRate]
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        sensors.forEach { $0.update(with: characteristic, result: result) }
    }
}
