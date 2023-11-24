//
//  BLEBikeSensor.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 24.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import CoreBluetooth

final class BLEBikeSensor: Sensor {
    
    private var oldCharacteristic: CyclingCharacteristic = .zero
    
    // BikeSpeedDistanceData
    private var travelDistance = Measurement<UnitLength>(value: 0, unit: .meters)
    private var totalTravelDistance = Measurement<UnitLength>(value: 0, unit: .meters)
    private var speed = Measurement<UnitSpeed>(value: 0, unit: .metersPerSecond)
    
    // BikeCadenceData
    private var gearRatio: Double = 1
    private var cadence: Int = 0
    
    var lastBikeCadenceData: BikeCadenceData?
    var lastBikeSpeedDistanceData: BikeSpeedDistanceData?
    // NOTE: wheelCircumference = wheelSize * pi
    var wheelSize: Double = 2.086
    
    override func getLastSensorDataList() -> [SensorData]? {
        var list = [SensorData]()
        if let lastBikeCadenceData {
            list.append(lastBikeCadenceData)
        }
        if let lastBikeSpeedDistanceData {
            list.append(lastBikeSpeedDistanceData)
        }
        return list
    }
    
    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        [.bicycleSpeed, .bicycleCadence, .bicycleDistance]
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        guard let data = characteristic.value else {
            return
        }
        switch characteristic.uuid {
        case GattAttributes.CHARACTERISTIC_CYCLING_SPEED_AND_CADENCE_MEASUREMENT.CBUUIDRepresentation:
            try? decodeSpeedCharacteristic(data: data, result: result)
        default:
            debugPrint("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    private func decodeSpeedCharacteristic(data: Data, result: (Result<Void, Error>) -> Void) throws {
        let characteristic = try CyclingCharacteristic(data: data)
        
        characteristic.travelDistance(with: wheelSize)
            .flatMap { totalTravelDistance = $0; return updateBikeSpeedDistanceData() }
        characteristic.distance(oldCharacteristic, wheelCircumference: wheelSize)
            .flatMap { travelDistance = travelDistance + $0; return updateBikeSpeedDistanceData() }
        characteristic.speed(oldCharacteristic, wheelCircumference: wheelSize)
            .flatMap { speed = $0; return updateBikeSpeedDistanceData() }
        
        characteristic.gearRatio(oldCharacteristic)
            .flatMap { gearRatio = $0; return updateeBikeCadenceData() }
        characteristic.cadence(oldCharacteristic)
            .flatMap { cadence = $0; return updateeBikeCadenceData() }
        
        oldCharacteristic = characteristic
        result(.success)
    }
    
    private func updateBikeSpeedDistanceData() {
        lastBikeCadenceData = nil
        lastBikeSpeedDistanceData = BikeSpeedDistanceData(timestamp: Date.now.timeIntervalSince1970,
                                                          speed: speed,
                                                          travelDistance: travelDistance,
                                                          totalTravelDistance: totalTravelDistance)
        debugPrint(lastBikeSpeedDistanceData?.description as Any)
    }
    
    private func updateeBikeCadenceData() {
        lastBikeSpeedDistanceData = nil
        lastBikeCadenceData = BikeCadenceData(timestamp: Date.now.timeIntervalSince1970,
                                              gearRatio: gearRatio,
                                              cadence: cadence)
        debugPrint(lastBikeCadenceData?.description as Any)
    }

    override func writeSensorDataToJson(json: NSMutableData, widgetDataFieldType: WidgetType) {
        do {
            let jsonEncoder = JSONEncoder()
            var data: Data?
            switch (widgetDataFieldType) {
            case .bicycleSpeed:
                if let lastBikeSpeedDistanceData = lastBikeSpeedDistanceData {
                    data = try jsonEncoder.encode([PointAttributes.sensorTagSpeed: OAOsmAndFormatter.getFormattedSpeed(Float(lastBikeSpeedDistanceData.speed.value))])
                }
                break;
            case .bicycleCadence:
                if let cadenceData = lastBikeCadenceData {
                    data = try jsonEncoder.encode([PointAttributes.sensorTagCadence: cadenceData.cadence])
                }
                break;
            case .bicycleDistance:
                if let lastBikeSpeedDistanceData = lastBikeSpeedDistanceData {
                    data = try jsonEncoder.encode([PointAttributes.sensorTagDistance: lastBikeSpeedDistanceData.travelDistance])
                }
                break;
            default:
                break;
            }
            if let data = data {
                json.append(data)
            }
        } catch {
            
        }
    }

}

extension BLEBikeSensor {
    final class BikeCadenceData: SensorData {
        let timestamp: TimeInterval
        let gearRatio: Double
        let cadence: Int
        
        var widgetFields: [SensorWidgetDataField]? {
            [SensorWidgetDataField(fieldType: .bicycleCadence,
                                   nameId: localizedString("external_device_characteristic_cadence"),
                                   unitNameId: "",
                                   numberValue: nil,
                                   stringValue: String(cadence))]
        }
        
        var description: String {
            "BikeCadenceData { timestamp=\(timestamp), gearRatio=\(gearRatio), cadence=\(cadence) }"
        }
        
        init(timestamp: TimeInterval, gearRatio: Double, cadence: Int) {
            self.timestamp = timestamp
            self.gearRatio = gearRatio
            self.cadence = cadence
        }
        
        func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField? {
            widgetFields?.first
        }
    }
    
    final class BikeSpeedDistanceData: SensorData {
        let timestamp: TimeInterval
        
        private(set) var travelDistance = Measurement<UnitLength>(value: 0, unit: .meters)
        private(set) var totalTravelDistance = Measurement<UnitLength>(value: 0, unit: .meters)
        private(set) var speed = Measurement<UnitSpeed>(value: 0, unit: .metersPerSecond)
        
        var description: String {
            "BikeSpeedDistanceData { timestamp=\(timestamp), speed=\(speed.value), travelDistance=\(travelDistance.value), totalTravelDistance=\(totalTravelDistance.value) }"
        }
        
        var widgetFields: [SensorWidgetDataField]? {
            [SensorWidgetDataField(fieldType: .bicycleSpeed,
                                   nameId: localizedString("external_device_characteristic_speed"),
                                   unitNameId: "",
                                   numberValue: nil,
                                   stringValue: OAOsmAndFormatter.getFormattedSpeed(Float(speed.value))),
             SensorWidgetDataField(fieldType: .bicycleDistance,
                                   nameId: localizedString("external_device_characteristic_distance"),
                                   unitNameId: "",
                                   numberValue: nil,
                                   stringValue: OAOsmAndFormatter.getFormattedDistance(Float(totalTravelDistance.value)))
            ]
        }
        
        init(timestamp: TimeInterval,
             speed: Measurement<UnitSpeed>,
             travelDistance: Measurement<UnitLength>,
             totalTravelDistance: Measurement<UnitLength>) {
            self.timestamp = timestamp
            self.speed = speed
            self.travelDistance = travelDistance
            self.totalTravelDistance = totalTravelDistance
        }
        
        func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField? {
            guard let widgetFields, widgetFields.count >= 2 else { return nil }
            if fieldType == .bicycleSpeed {
                return widgetFields.first
            } else if fieldType == .bicycleDistance {
                return widgetFields[1]
            }
            return nil
        }
    }
}
