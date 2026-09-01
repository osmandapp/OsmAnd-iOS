//
//  Sensor.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 16.10.2023.
//

import CoreBluetooth

class Sensor {
    private static let defaultActualDataTimePeriod: TimeInterval = 10

    var timestamp: Double = 0
    var device: Device!
    var sensorId: String!
    private var lastActualDataTimeByWidgetId = [String: TimeInterval]()

    init(timestamp: Double = Date().timeIntervalSince1970,
         device: Device,
         sensorId: String) {
        self.timestamp = timestamp
        self.device = device
        self.sensorId = sensorId
    }

    func update(with characteristic: CBCharacteristic, result: @escaping (Result<Void, Error>) -> Void) { }

    func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        nil
    }

    func getLastSensorDataList(for widgetType: WidgetType) -> [SensorData]? {
        nil
    }

    func writeSensorDataToJson(json: NSMutableData, widgetDataFieldType: WidgetType) {
    }

    func hasActualData(for widgetType: WidgetType) -> Bool {
        guard let lastActualDataTime = lastActualDataTimeByWidgetId[widgetType.id] else {
            return false
        }
        return Date.now.timeIntervalSince1970 - lastActualDataTime < actualDataTimePeriod(for: widgetType)
    }

    func markActualData(for widgetType: WidgetType) {
        lastActualDataTimeByWidgetId[widgetType.id] = Date.now.timeIntervalSince1970
    }

    func resetActualData(for widgetType: WidgetType) {
        lastActualDataTimeByWidgetId[widgetType.id] = 0
    }

    func actualDataTimePeriod(for widgetType: WidgetType) -> TimeInterval {
        Self.defaultActualDataTimePeriod
    }
}

protocol SensorData {
    var widgetFields: [SensorWidgetDataField]? { get }

    func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField?
}

extension SensorData {

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
