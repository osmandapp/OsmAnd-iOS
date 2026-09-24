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

    init() {
        super.init(deviceType: .BLE_HEART_RATE)
        sensors.append(BLEHeartRateSensor(device: self, sensorId: "heart_rate"))
    }

    override func update(with characteristic: CBCharacteristic, result: @escaping (Result<Void, Error>) -> Void) {
        sensors.forEach { $0.update(with: characteristic, result: result) }
    }
}
