//
//  BLETemperatureDevice.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 12.10.2023.
//

import Foundation
import CoreBluetooth

final class BLETemperatureDevice: Device {
    
    override class var getServiceUUID: String {
        GattAttributes.SERVICE_TEMPERATURE
    }
    
    init() {
        super.init(deviceType: .BLE_TEMPERATURE)
        sensors.append(BLETemperatureSensor(device: self, sensorId: "temperature"))
    }
    
    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        [.temperature]
    }
    
    override var getServiceConnectedImage: UIImage {
        UIImage(named: "widget_weather_temperature_day")!
    }
    
    override var getWidgetValue: String? {
        //        if let sensor = sensors.first(where: { $0 is BLEHeartRateSensor }) as? BLEHeartRateSensor {
        //            return sensor.lastHeartRateData!.heartRate == 0
        //            ? "-"
        //            : String(sensor.lastHeartRateData!.heartRate) + " " + localizedString("beats_per_minute_short")
        //        }
        return nil
    }
    
    override var getDataFields: Dictionary<String, String>? {
        //        if let sensor = sensors.first(where: { $0 is BLEHeartRateSensor }) as? BLEHeartRateSensor {
        //            if let lastHeartRateData = sensor.lastHeartRateData {
        //                return [localizedString("map_widget_ant_heart_rate"):
        //                            lastHeartRateData.heartRate == 0
        //                        ? "-"
        //                        : String(lastHeartRateData.heartRate) + " " + localizedString("beats_per_minute_short")]
        //            } else {
        //                return [localizedString("map_widget_ant_heart_rate"): "-"];
        //            }
        //
        //        }
        return nil
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        sensors.forEach{ $0.update(with: characteristic, result: result)}
    }
}
