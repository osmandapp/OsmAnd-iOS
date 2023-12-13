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
    
    override var getServiceConnectedImage: UIImage {
        UIImage(named: "widget_weather_temperature")!
    }
    
    override var getDataFields: [[String: String]]? {
        if let sensor = sensors.first(where: { $0 is BLETemperatureSensor }) as? BLETemperatureSensor {
            if let lastTemperatureData = sensor.lastTemperatureData {
                return [[localizedString("shared_string_temperature"):
                            lastTemperatureData.temperature == 0.0
                        ? "-"
                        : String(lastTemperatureData.temperature) + " " + localizedString("degree_celsius")]]
            } else {
                return [[localizedString("shared_string_temperature"): "-"]]
            }
        }
        return nil
    }
    
    init() {
        super.init(deviceType: .BLE_TEMPERATURE)
        sensors.append(BLETemperatureSensor(device: self, sensorId: "temperature"))
    }
    
    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        [.temperature]
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        sensors.forEach { $0.update(with: characteristic, result: result) }
    }
}
