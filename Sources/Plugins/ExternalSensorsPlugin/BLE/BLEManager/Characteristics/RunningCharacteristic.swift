//
//  RunningCharacteristic.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 01.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

private extension Flag {
    static let strideLength: Flag = 0x01
    static let totalDistance: Flag = 0x02
    static let isRunning: Flag = 0x04
}

struct RunningCharacteristic {
    let speed: Measurement<UnitSpeed>
    let cadence: Int
    let strideLength: Measurement<UnitLength>?
    let totalDistance: Measurement<UnitLength>?
    let isRunning: Bool
    
    init(data: Data) throws {
        let speedValue = Double(try data.read(fromOffset: 1) as UInt16) / 256
        speed = Measurement(value: speedValue, unit: .metersPerSecond)
        cadence = Int(try data.read(fromOffset: 3) as UInt8)
        
        let bitFlags: UInt8 = try data.read(fromOffset: 0)
        
        isRunning = Flag.isAvailable(bits: bitFlags, flag: .isRunning)
        
        strideLength = try Flag.isAvailable(bits: bitFlags, flag: .strideLength) ? {
            let strideLengthValue: UInt16 = try data.read(fromOffset: 4)
            return Measurement(value: Double(strideLengthValue), unit: .centimeters)
        }() : nil
        
        totalDistance = try Flag.isAvailable(bits: bitFlags, flag: .totalDistance) ? {
            let offset = Flag.isAvailable(bits: bitFlags, flag: .strideLength) ? 6 : 4
            let totalDistanceValue: UInt32 = try data.read(fromOffset: offset)
            return Measurement(value: Double(Double(totalDistanceValue)), unit: .decameters)
        }() : nil
    }
}
