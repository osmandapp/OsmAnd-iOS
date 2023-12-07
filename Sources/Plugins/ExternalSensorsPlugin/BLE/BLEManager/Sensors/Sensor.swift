//
//  Sensor.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 16.10.2023.
//

import CoreBluetooth

class Sensor {
    var timestamp: Double = 0
    var device: Device!
    var sensorId: String!
    
    init(timestamp: Double = Date().timeIntervalSince1970,
         device: Device,
         sensorId: String) {
        self.timestamp = timestamp
        self.device = device
        self.sensorId = sensorId
    }
    
    func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) { }
    
    func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        nil
    }
    
    func getLastSensorDataList(for widgetType: WidgetType) -> [SensorData]? {
        nil
    }
}

protocol SensorData {
    var dataFields: [SensorDataField] { get }
    var extraDataFields: [SensorDataField] { get }
    var widgetFields: [SensorWidgetDataField]? { get }
    
    func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField?
}

extension SensorData {
    var dataFields: [SensorDataField] {
        return []
    }
    
    var extraDataFields: [SensorDataField] {
        return []
    }
    
    var widgetFields: [SensorWidgetDataField]? {
        return nil
    }
    
    func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField? {
        guard let widgetFields else {
            return nil
        }
        
        for widgetField in widgetFields where widgetField.fieldType == fieldType {
            return widgetField
        }
        return nil
    }
}
