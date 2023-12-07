//
//  PointAttributes.swift
//  OsmAnd Maps
//
//  Created by Skalii on 22.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@objc(OAPointAttributes)
@objcMembers
final class PointAttributes : NSObject {

    static let pointElevation = "ele"
    static let pointSpeed = "speed"
    static let sensorTagHartRate = "hr"
    static let sensorTagSpeed = "speed_sensor"
    static let sensorTagCadence = "cad"
    static let sensorTagBikePower = "power"
    static let sensorTagTemperature = "wtemp"
    static let sensorTagDistance = "bike_distance_sensor"

    let distance: Float
    let timeDiff: Float
    let firstPoint: Bool
    let lastPoint: Bool

    var speed: Float = 0.0
    var elevation: Float = 0.0
    var heartRate: Float = 0.0
    var sensorSpeed: Float = 0.0
    var bikeCadence: Float = 0.0
    var bikePower: Float = 0.0
    var temperature: Float = 0.0

    init(distance: Float, timeDiff: Float, firstPoint: Bool, lastPoint: Bool) {
        self.distance = distance
        self.timeDiff = timeDiff
        self.firstPoint = firstPoint
        self.lastPoint = lastPoint
    }

    func getAttributeValue(for tag: String) -> Float? {
        switch tag {
        case Self.pointSpeed:
            return speed
        case Self.pointElevation:
            return elevation
        case Self.sensorTagHartRate:
            return heartRate
        case Self.sensorTagSpeed:
            return sensorSpeed
        case Self.sensorTagCadence:
            return bikeCadence
        case Self.sensorTagBikePower:
            return bikePower
        case Self.sensorTagTemperature:
            return temperature
        default:
            return nil
        }
    }

    func setAttributeValue(for tag: String, value: Float) {
        switch tag {
        case Self.pointSpeed:
            speed = value
        case Self.pointElevation:
            elevation = value
        case Self.sensorTagHartRate:
            heartRate = value
        case Self.sensorTagSpeed:
            sensorSpeed = value
        case Self.sensorTagCadence:
            bikeCadence = value
        case Self.sensorTagBikePower:
            bikePower = value
        case Self.sensorTagTemperature:
            temperature = value
        default:
            break
        }
    }

    func hasValidValue(for tag: String) -> Bool {
        guard let value = getAttributeValue(for: tag) else { return false }
        
        if Self.sensorTagTemperature == tag || Self.pointElevation == tag {
            return !value.isNaN
        } else {
            return value > 0
        }
    }

}
