//
//  Data+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 15.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

protocol ReadableError: Error {
    var title: String { get }
    var readableMessage: String { get }
}

extension ReadableError {
    var title: String {
        "Error"
    }
}

enum ReservedSFloatValues: Int16 {
    case positiveInfinity = 0x07FE
    case nan = 0x07FF
    case nres = 0x0800
    case reserved = 0x0801
    case negativeInfinity = 0x0802
    
    static let firstReservedValue = ReservedSFloatValues.positiveInfinity
}

enum ReservedFloatValues: UInt32 {
    case positiveInfinity = 0x007FFFFE
    case nan = 0x007FFFFF
    case nres = 0x00800000
    case reserved = 0x00800001
    case negativeInfinity = 0x00800002
    
    static let firstReservedValue = ReservedFloatValues.positiveInfinity
}

extension Double {
    static var reservedValues: [Double] {
        [.infinity, .nan, .nan, .nan, -.infinity]
    }
}

extension Data {

    enum DataError: ReadableError {
        case outOfRange
        
        var readableMessage: String {
            "Cannot parse data"
        }
    }
    
    func read<R: FixedWidthInteger>(fromOffset offset: Int = 0) throws -> R {
        let length = MemoryLayout<R>.size

        guard offset + length <= count else { throw DataError.outOfRange }

        return subdata(in: offset ..< offset + length).withUnsafeBytes { $0.load(as: R.self) }
    }
    
    func readSFloat(from offset: Int = 0) throws -> Float {
        let tempData: UInt16 = try read(fromOffset: offset)
        var mantissa = Int16(tempData & 0x0FFF)
        var exponent = Int8(tempData >> 12)
        if exponent >= 0x0008 {
            exponent = -( (0x000F + 1) - exponent )
        }
        
        var output: Float32 = 0
        
        if mantissa >= ReservedSFloatValues.firstReservedValue.rawValue && mantissa <= ReservedSFloatValues.negativeInfinity.rawValue {
            output = Float32(Double.reservedValues[Int(mantissa - ReservedSFloatValues.firstReservedValue.rawValue)])
        } else {
            if mantissa > 0x0800 {
                mantissa = -((0x0FFF + 1) - mantissa)
            }
            let magnitude = pow(10.0, Double(exponent))
            output = Float32(mantissa) * Float32(magnitude)
        }
        
        return output
    }
    
    func readFloat(from offset: Int = 0) throws -> Float {
        let tempData: UInt32 = try read(fromOffset: offset)
        var mantissa = Int32(tempData & 0x00FFFFFF)
        let exponent = Int8(bitPattern: UInt8(tempData >> 24))
        
        var output: Float32 = 0
        
        if mantissa >= Int32(ReservedFloatValues.firstReservedValue.rawValue) && mantissa <= Int32(ReservedFloatValues.negativeInfinity.rawValue) {
            output = Float32(Double.reservedValues[Int(mantissa - Int32(ReservedSFloatValues.firstReservedValue.rawValue))])
        } else {
            if mantissa >= 0x800000 {
                mantissa = -((0xFFFFFF + 1) - mantissa)
            }
            let magnitude = pow(10.0, Double(exponent))
            output = Float32(mantissa) * Float32(magnitude)
        }
        
        return output
    }
    
    func readDate(from offset: Int = 0) throws -> Date {
        var offset = offset
        let year: UInt16 = try read(fromOffset: offset); offset += 2
        let month: UInt8 = try read(fromOffset: offset); offset += 1
        let day: UInt8 = try read(fromOffset: offset); offset += 1
        let hour: UInt8 = try read(fromOffset: offset); offset += 1
        let min: UInt8 = try read(fromOffset: offset); offset += 1
        let sec: UInt8 = try read(fromOffset: offset); offset += 1
        
        let calendar = Calendar.current
        let dateComponents = DateComponents(calendar: .current,
                                            year: Int(year),
                                            month: Int(month),
                                            day: Int(day),
                                            hour: Int(hour),
                                            minute: Int(min),
                                            second: Int(sec))
        return calendar.date(from: dateComponents)!
    }
}
