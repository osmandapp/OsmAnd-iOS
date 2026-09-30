//
//  BLETemperatureDevice.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 12.10.2023.
//

import Foundation
import CoreBluetooth

final class BLETemperatureDevice: Device {
        
    override var deviceServiceName: String {
        "Temperature"
    }
    
    override class var getServiceUUID: String {
        GattAttributes.SERVICE_TEMPERATURE
    }
    
    override var getServiceConnectedImage: UIImage? {
        .widgetWeatherTemperature
    }
    
    override var getServiceDisconnectedImage: UIImage? {
        .icCustomSensorThermometer
    }

    init() {
        super.init(deviceType: .BLE_TEMPERATURE)
        sensors.append(BLETemperatureSensor(device: self, sensorId: "temperature"))
    }

    override func update(with characteristic: CBCharacteristic, result: @escaping (Result<Void, Error>) -> Void) {
        sensors.forEach { $0.update(with: characteristic, result: result) }
    }
}
