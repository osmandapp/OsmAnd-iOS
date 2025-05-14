//
//  OBDVehicleMetricsSensor.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 14.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class OBDVehicleMetricsSensor: Sensor {
    private(set) var lastRunningCadenceData: RunningCadenceData?
    private(set) var lastRunningSpeedData: RunningSpeedData?
    private(set) var lastRunningDistanceData: RunningDistanceData?
    private(set) var lastRunningStrideLengthData: RunningStrideLengthData?
    
    override func getLastSensorDataList(for widgetType: WidgetType) -> [SensorData]? {
        if widgetType == .bicycleCadence {
            return [lastRunningCadenceData].compactMap { $0 }
        } else if widgetType == .bicycleSpeed {
            return [lastRunningSpeedData].compactMap { $0 }
        } else if widgetType == .bicycleDistance {
            return [lastRunningDistanceData].compactMap { $0 }
        }
        return nil
    }
    
    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        [.bicycleCadence, .bicycleSpeed, .bicycleDistance]
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        guard let data = characteristic.value else {
            return
        }
        
        switch characteristic.uuid {
        case "2AF0".CBUUIDRepresentation:
            print("")
        case "AF1".CBUUIDRepresentation:
            print("")
        default:
            debugPrint("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    private func decodeRunningCharacteristic(data: Data, result: (Result<Void, Error>) -> Void) throws {
        let characteristic = try RunningCharacteristic(data: data)
        let timestamp = Date.now.timeIntervalSince1970
        lastRunningCadenceData = RunningCadenceData(timestamp: timestamp, cadence: characteristic.cadence)
        lastRunningSpeedData = RunningSpeedData(timestamp: timestamp, speed: characteristic.speed)
        if let totalDistance = characteristic.totalDistance {
            lastRunningDistanceData = RunningDistanceData(timestamp: timestamp, totalDistance: totalDistance)
        }
        if let strideLength = characteristic.strideLength {
            lastRunningStrideLengthData = RunningStrideLengthData(timestamp: timestamp, strideLength: strideLength)
        }
        result(.success)
    }
    
    final class RunningCadenceData: SensorData {
        let timestamp: TimeInterval
        let cadence: Int
        
        init(timestamp: TimeInterval, cadence: Int) {
            self.timestamp = timestamp
            self.cadence = cadence
        }
        
        var widgetFields: [SensorWidgetDataField]? {
            [SensorWidgetDataField(fieldType: .bicycleCadence,
                                   nameId: localizedString("external_device_characteristic_cadence"),
                                   unitNameId: localizedString("revolutions_per_minute_unit"),
                                   numberValue: nil,
                                   stringValue: String(cadence))]
        }
        
        var description: String {
            "RunningCadenceData { timestamp=\(timestamp), cadence=\(cadence) }"
        }
        
        func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField? {
            widgetFields?.first
        }
    }
    
    final class RunningSpeedData: SensorData {
        let timestamp: TimeInterval
        private(set) var speed = Measurement<UnitSpeed>(value: 0, unit: .metersPerSecond)
        
        init(timestamp: TimeInterval, speed: Measurement<UnitSpeed>) {
            self.timestamp = timestamp
            self.speed = speed
        }
        
        var widgetFields: [SensorWidgetDataField]? {
            [SensorSpeedWidgetDataField(fieldType: .bicycleSpeed,
                                        nameId: localizedString("external_device_characteristic_speed"),
                                        unitNameId: "",
                                        numberValue: NSNumber(value: speed.value),
                                        stringValue: nil)]
        }
        
        var description: String {
            "RunningSpeedData { timestamp=\(timestamp), speed=\(speed.value) }"
        }
        
        func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField? {
            widgetFields?.first
        }
    }
    
    final class RunningDistanceData: SensorData {
        let timestamp: TimeInterval
        private(set) var totalDistance = Measurement<UnitLength>(value: 0, unit: .meters)
        
        init(timestamp: TimeInterval, totalDistance: Measurement<UnitLength>) {
            self.timestamp = timestamp
            self.totalDistance = totalDistance
        }
        
        var widgetFields: [SensorWidgetDataField]? {
            [SensorDistanceWidgetDataField(fieldType: .bicycleDistance,
                                           nameId: localizedString("external_device_characteristic_distance"),
                                           unitNameId: "",
                                           numberValue: NSNumber(value: totalDistance.value / 10),
                                           stringValue: nil)
            ]
        }
        
        var description: String {
            "RunningDistanceData { timestamp=\(timestamp), totalDistance=\(totalDistance.value / 10) }"
        }
        
        func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField? {
            widgetFields?.first
        }
    }
    
    final class RunningStrideLengthData: SensorData {
        let timestamp: TimeInterval
        let strideLength: Measurement<UnitLength>
        
        init(timestamp: TimeInterval, strideLength: Measurement<UnitLength>) {
            self.timestamp = timestamp
            self.strideLength = strideLength
        }
        
        var widgetFields: [SensorWidgetDataField]? {
            [SensorDistanceWidgetDataField(fieldType: .bicycleDistance,
                                           nameId: localizedString("external_device_characteristic_stride_length"),
                                           unitNameId: "",
                                           numberValue: NSNumber(value: strideLength.value / 100),
                                           stringValue: nil)
            ]
        }
        
        var description: String {
            "RunningStrideLengthData { timestamp=\(timestamp), strideLength=\(strideLength.value / 100) }"
        }
        
        func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField? {
            widgetFields?.first
        }
    }
}
