//
//  BLEBikeSensor.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 24.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import CoreBluetooth

class BLEBikeSensor: Sensor {
    
    static let WheelFlagMask: UInt8    = 0b01
    static let CrankFlagMask: UInt8    = 0b10
    
    var firstWheelRevolutions: Int = -1
    var lastWheelRevolutions = -1
    var lastWheelEventTime = -1
    var wheelCadence: Float = -1
    var lastCrankRevolutions = -1
    var lastCrankEventTime = -1
    
    var wheelSize: Float = 2.086 //m
    
    var lastBikeCadenceData: BikeCadenceData?
    var lastBikeSpeedDistanceData: BikeSpeedDistanceData?
    
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
    
    final class BikeCadenceData: SensorData {
        let timestamp: TimeInterval
        let gearRatio: Float
        let cadence: Int
        
        init(timestamp: TimeInterval, gearRatio: Float, cadence: Int) {
            self.timestamp = timestamp
            self.gearRatio = gearRatio
            self.cadence = cadence
        }
        
        func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField? {
            widgetFields?.first
        }
        
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
    }
    
    final class BikeSpeedDistanceData: SensorData {
        let timestamp: TimeInterval
        let speed: Float
        let distance: Float
        let totalDistance: Float
        
        init(timestamp: TimeInterval, speed: Float, distance: Float, totalDistance: Float) {
            self.timestamp = timestamp
            self.speed = speed
            self.distance = distance
            self.totalDistance = totalDistance
        }
        
        var description: String {
            "BikeSpeedDistanceData { timestamp=\(timestamp), speed=\(speed), distance=\(distance), totalDistance=\(totalDistance) }"
        }
        
        func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField? {
            widgetFields?.first
        }
        
        var widgetFields: [SensorWidgetDataField]? {
            [SensorWidgetDataField(fieldType: .bicycleSpeed,
                                   nameId: localizedString("external_device_characteristic_speed"),
                                   unitNameId: "",
                                   numberValue: nil,
                                   stringValue: String(speed)),
             SensorWidgetDataField(fieldType: .bicycleDistance,
                                   nameId: localizedString("external_device_characteristic_distance"),
                                   unitNameId: "",
                                   numberValue: nil,
                                   stringValue: String(totalDistance))
            ]
        }
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        guard let data = characteristic.value else {
            return
        }
        switch characteristic.uuid {
        case GattAttributes.CHARACTERISTIC_CYCLING_SPEED_AND_CADENCE_MEASUREMENT.CBUUIDRepresentation:
            decodeSpeedCharacteristic(data: data as NSData, result: result)
        default:
            debugPrint("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    private func decodeSpeedCharacteristic(data: NSData, result: (Result<Void, Error>) -> Void) {
        var flags: UInt8 = 0
        data.getBytes(&flags, range: NSRange(location: 0, length: 1))
        
        let wheelRevPresent = ((flags & Self.WheelFlagMask) > 0)
        let crankRevPreset = ((flags & Self.CrankFlagMask) > 0)
        
        var wheel: UInt32 = 0
        var wheelTime: UInt16 = 0
        var crank: UInt16 = 0
        var crankTime: UInt16 = 0
        
        var currentOffset = 1
        var length = 0
        
        if wheelRevPresent {
            length = MemoryLayout<UInt32>.size
            data.getBytes(&wheel, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
            
            length = MemoryLayout<UInt16>.size
            data.getBytes(&wheelTime, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
            
            let wheelRevolutions = Int(CFSwapInt32LittleToHost(wheel))
            print("wheelRevolutions: \(wheelRevolutions)")
            let lastWheelEventTime = Int(TimeInterval( Double(CFSwapInt16LittleToHost(wheelTime))))
            let circumference = wheelSize
            
            if firstWheelRevolutions < 0 {
                firstWheelRevolutions = wheelRevolutions
            }
            
            if self.lastWheelEventTime == lastWheelEventTime {
                let totalDistance: Float = Float(wheelRevolutions) * circumference
                let distance: Float = Float(wheelRevolutions - firstWheelRevolutions) * circumference // m
                var speed: Float = 0
                
                if lastBikeSpeedDistanceData != nil {
                    speed = lastBikeSpeedDistanceData!.speed
                }
                createBikeSpeedDistanceData(speed: speed, distance: distance, totalDistance: totalDistance)
                result(.success)
            } else if lastWheelRevolutions >= 0 {
                let timeDifference: Float
                
                if lastWheelEventTime < self.lastWheelEventTime {
                    timeDifference = Float((65535 + lastWheelEventTime - self.lastWheelEventTime)) / 1024.0
                } else {
                    timeDifference = Float((lastWheelEventTime - self.lastWheelEventTime)) / 1024.0
                }
                
                let distanceDifference = Float(wheelRevolutions - lastWheelRevolutions) * circumference
                let totalDistance: Float = Float(wheelRevolutions) * circumference
                let distance: Float = Float(wheelRevolutions - firstWheelRevolutions) * circumference
                let speed = distanceDifference / timeDifference
                
                wheelCadence = Float((wheelRevolutions - lastWheelRevolutions)) * 60.0 / timeDifference
                createBikeSpeedDistanceData(speed: speed, distance: distance, totalDistance: totalDistance)
                result(.success)
            }
            
            lastWheelRevolutions = wheelRevolutions
            self.lastWheelEventTime = lastWheelEventTime
        } else if crankRevPreset {
            length = MemoryLayout<UInt16>.size
            data.getBytes(&crank, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
            
            length = MemoryLayout<UInt16>.size
            data.getBytes(&crankTime, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
            
            let crankRevolutions    = Int(CFSwapInt16LittleToHost(crank))
            print("crankRevolutions: \(crankRevolutions)")
            
            let lastCrankEventTime  = Int(TimeInterval( Double(CFSwapInt16LittleToHost(crankTime))))
            
            if lastCrankRevolutions >= 0 {
                let timeDifference: Float
                
                if lastCrankEventTime < self.lastCrankEventTime {
                    timeDifference = Float((65535 + lastCrankEventTime - self.lastCrankEventTime)) / 1024.0
                } else {
                    timeDifference = Float((lastCrankEventTime - self.lastCrankEventTime)) / 1024.0
                }
                
                let crankCadence = Float((crankRevolutions - lastCrankRevolutions)) * 60.0 / timeDifference
                
                if crankCadence > 0 {
                    let gearRatio = wheelCadence / crankCadence
                    createBikeCadenceData(gearRatio: gearRatio, crankCadence: Int(crankCadence.rounded()))
                    result(.success)
                }
            }
            
            lastCrankRevolutions = crankRevolutions
            self.lastCrankEventTime = lastCrankEventTime
        }
    }
    
    private func createBikeSpeedDistanceData(speed: Float,
                                             distance: Float,
                                             totalDistance: Float) {
        lastBikeSpeedDistanceData = BikeSpeedDistanceData(timestamp: Date.now.timeIntervalSince1970,
                                                          speed: speed,
                                                          distance: distance,
                                                          totalDistance: totalDistance)
        print(lastBikeSpeedDistanceData?.description)
    }
    
    private func createBikeCadenceData(gearRatio: Float, crankCadence: Int) {
        lastBikeCadenceData = BikeCadenceData(timestamp: Date.now.timeIntervalSince1970, gearRatio: gearRatio, cadence: crankCadence)
        print(lastBikeCadenceData?.description)
    }
}

