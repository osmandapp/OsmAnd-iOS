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
        UIImage(named: "widget_sensor_speed")
    }
    
    override var getServiceDisconnectedImage: UIImage? {
        UIImage(named: "ic_custom_sensor_speed_outlined")
    }

    init() {
        super.init(deviceType: .BLE_RUNNING_SCDS)
        sensors.append(BLERunningSensor(device: self, sensorId: "running"))
    }

    override func update(with characteristic: CBCharacteristic, result: @escaping (Result<Void, Error>) -> Void) {
        sensors.forEach { $0.update(with: characteristic, result: result) }
    }
}
