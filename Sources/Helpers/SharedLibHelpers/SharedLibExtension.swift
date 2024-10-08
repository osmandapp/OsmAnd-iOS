//
//  SharedLibExtension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 26.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//
import OsmAndShared

extension Array {
     func toKotlinArray<Item: AnyObject>() -> KotlinArray<Item> {
        return KotlinArray(size: Int32(self.count)) { (i: KotlinInt) in
            guard let item = self[i.intValue] as? Item else {
                 fatalError("Element at index \(i) cannot be cast to \(Item.self)")
             }
             return item
        }
    }
}

@objc final class ArraySplitSegmentConverter: NSObject {
    @objc static func toKotlinArray(from array: [SplitSegment]) -> KotlinArray<SplitSegment> {
        array.toKotlinArray()
    }
}

@objc(OASPointAttributes)
extension PointAttributes {
    static let sensorTagHeartRate = GPXTPX_PREFIX + "hr"
    static let sensorTagSpeed = OSMAND_EXTENSIONS_PREFIX + "speed_sensor"
    static let sensorTagCadence = GPXTPX_PREFIX + "cad"
    static let sensorTagBikePower = GPXTPX_PREFIX + "power"
    static let SENSOR_TAG_TEMPERATURE = "temp_sensor"
    static let sensorTagTemperatureW = GPXTPX_PREFIX + "wtemp"
    static let sensorTagTemperatureA = GPXTPX_PREFIX + "atemp"
    static let sensorTagDistance = OSMAND_EXTENSIONS_PREFIX + "bike_distance_sensor"
    static let pointElevation = "ele" // point_elevation
    static let pointSpeed = "speed" // point_speed

//    static let DEV_RAW_ZOOM = "raw_zoom"
//    static let DEV_ANIMATED_ZOOM = "animated_zoom"
//    static let DEV_INTERPOLATION_OFFSET_N = "offset"
//
//    static let POINT_SPEED = "point_speed"
//    static let POINT_ELEVATION = "point_elevation"
    
    static let GPXTPX_PREFIX = "gpxtpx:"
    static let OSMAND_EXTENSIONS_PREFIX = "osmand:"
}

//const val POINT_SPEED = "point_speed"
//const val POINT_ELEVATION = "point_elevation"

// Old code
//    static let pointElevation = "ele"
//    static let pointSpeed = "speed"
//    static let sensorTagHeartRate = "hr"
//    static let sensorTagSpeed = "speed_sensor"
//    static let sensorTagCadence = "cad"
//    static let sensorTagBikePower = "power"
//    static let sensorTagTemperatureW = "wtemp"
//    static let sensorTagTemperatureA = "atemp"
//    static let sensorTagDistance = "bike_distance_sensor"

