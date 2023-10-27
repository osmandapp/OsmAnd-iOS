//
//  BLEHeartRateSensor.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 12.10.2023.
//

import CoreBluetooth


final class BLEHeartRateSensor: Sensor {
    
    final class HeartRateData: SensorData {
        var heartRate: Int = 0
        var bodyPart: BodyPart = .other
    }
    
    private(set) var heartRateData = HeartRateData()
    
    enum BodyPart: Int {
        case other
        case chest
        case wrist
        case finger
        case hand
        case earLobe
        case foot
        
        var description: String {
            switch self {
            case .other:
                return localizedString("shared_string_other")
            case .chest:
                return localizedString("shared_string_chest")
            case .wrist:
                return localizedString("shared_string_finger")
            case .finger:
                return localizedString("shared_string_wrist")
            case .hand:
                return localizedString("shared_string_hand")
            case .earLobe:
                return localizedString("shared_string_ear_lobe")
            case .foot:
                return localizedString("shared_string_foot")
            }
        }
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        switch characteristic.uuid {
        case GattAttributes.CHARACTERISTIC_HEART_RATE_MEASUREMENT.CBUUIDRepresentation:
            let heartRate = heartRate(from: characteristic)
            if heartRateData.heartRate != heartRate {
                heartRateData.heartRate = heartRate
                result(.success)
            }
            debugPrint("bpm: \(heartRateData.heartRate)")
        case GattAttributes.CHARACTERISTIC_HEART_RATE_BODY_PART.CBUUIDRepresentation:
            heartRateData.bodyPart = bodyLocation(from: characteristic)
            debugPrint("bodyPart: \(heartRateData.bodyPart.description)")
        default:
            debugPrint("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}

// MARK: Parser
extension BLEHeartRateSensor {
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        
        // The heart rate mesurement is in the 2nd, or in the 2nd and 3rd bytes, i.e. one one or in two bytes
        // The first byte of the first bit specifies the length of the heart rate data, 0 == 1 byte, 1 == 2 bytes
        let firstBitValue = byteArray[0] & 0x01
        if firstBitValue == 0 {
            // Heart Rate Value Format is in the 2nd byte
            return Int(byteArray[1])
        } else {
            // Heart Rate Value Format is in the 2nd and 3rd bytes
            return (Int(byteArray[1]) << 8) + Int(byteArray[2])
        }
    }
    
    private func bodyLocation(from characteristic: CBCharacteristic) -> BodyPart {
        guard let characteristicData = characteristic.value,
              let byte = characteristicData.first else { return .other }
        if let bodyPart = BodyPart(rawValue: Int(byte)) {
            return bodyPart
        }
        return .other
    }
    
}

