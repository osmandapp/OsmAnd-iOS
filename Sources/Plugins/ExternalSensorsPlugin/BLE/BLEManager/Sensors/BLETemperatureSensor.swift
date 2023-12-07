//
//  BLETemperatureSensor.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import CoreBluetooth

final class BLETemperatureSensor: Sensor {
    
    final class TemperatureData: SensorData {
        
        var timestamp: TimeInterval = Date.now.timeIntervalSince1970
        var temperature: Double = 0.0
        
        var widgetFields: [SensorWidgetDataField]? {
            return [SensorWidgetDataField(fieldType: .temperature,
                                          nameId: localizedString("shared_string_temperature"),
                                          unitNameId: localizedString("degree_celsius"),
                                          numberValue: nil,
                                          stringValue: String(temperature))]
        }
        
        func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField? {
            widgetFields?.first
        }
    }

    var lastTemperatureData: TemperatureData?
    
    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        [.temperature]
    }
    
    override func getLastSensorDataList(for widgetType: WidgetType) -> [SensorData]? {
        guard widgetType == .temperature else { return nil }
        return [lastTemperatureData].compactMap { $0 }
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        guard let data = characteristic.value else {
            return
        }
        
        switch characteristic.uuid {
        case GattAttributes.CHAR_TEMPERATURE_MEASUREMENT.CBUUIDRepresentation:
            let dataFromSensor = dataToSignedBytes16(value: data as NSData, count: 2)
            let ambientTemperature = Double(dataFromSensor[1]) / 128
            
            if lastTemperatureData == nil {
                lastTemperatureData = TemperatureData()
            }
            if let lastTemperatureData {
                if lastTemperatureData.temperature != ambientTemperature {
                    lastTemperatureData.temperature = ambientTemperature
                    lastTemperatureData.timestamp = Date.now.timeIntervalSince1970
                    result(.success)
                }
                debugPrint("temperature: \(lastTemperatureData.timestamp)")
            }
        default:
            debugPrint("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    private func dataToSignedBytes16(value: NSData, count: Int) -> [Int16] {
        var array = [Int16](repeating: 0, count: count)
        value.getBytes(&array,
                       length: count * MemoryLayout<Int16>.size)
        return array
    }

    override func writeSensorDataToJson(json: NSMutableData, widgetDataFieldType: WidgetType) {
        if let lastTemperatureData {
            do {
                let data = try JSONEncoder().encode([PointAttributes.sensorTagTemperature: String(lastTemperatureData.temperature)])
                json.append(data)
            } catch {
                debugPrint("BLE failed writeSensorDataToJson: temperature - \(lastTemperatureData.temperature) | error: \(error.localizedDescription)")
            }
        }
    }
}
