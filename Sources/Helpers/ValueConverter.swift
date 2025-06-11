//
//  ValueConverter.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 04.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

enum ValueConverter {
    static func toFloat(_ value: Any?) -> Float {
        guard let value else { return 0 }
      
        switch value {
        case let float as Float:
            return float
        case let number as NSNumber:
            return number.floatValue
        case let string as String:
            return Float(string.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        case let int as Int:
            return Float(int)
        case let double as Double:
            return Float(double)
        case let bool as Bool:
            return bool ? 1 : 0
        default:
            return 0
        }
    }
    
    static func toInt(_ value: Any?) -> Int {
        guard let value else { return 0 }
        
        switch value {
        case let int as Int:
            return int
        case let number as NSNumber:
            return number.intValue
        case let string as String:
            return Int(string.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        case let float as Float:
            return Int(float)
        case let double as Double:
            return Int(double)
        case let bool as Bool:
            return bool ? 1 : 0
        default:
            return 0
        }
    }
}

extension Any? {
    var asInt: Int {
        ValueConverter.toInt(self)
    }

    var asFloat: Float {
        ValueConverter.toFloat(self)
    }
}

