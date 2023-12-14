//
//  BLEBatterySensor.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 16.10.2023.
//

import CoreBluetooth

final class BatteryData: SensorData {
    var timestamp: TimeInterval = 0
    var batteryLevel: Int = -1
}

final class BLEBatterySensor: Sensor {
    private(set) var lastBatteryData = BatteryData()
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        switch characteristic.uuid {
        case GattAttributes.CHARACTERISTIC_BATTERY.CBUUIDRepresentation:
            if let value = characteristic.value, !value.isEmpty {
                lastBatteryData.batteryLevel = Int(value[0])
                lastBatteryData.timestamp = Date().timeIntervalSince1970
                result(.success)
                debugPrint("batteryLevel: \(lastBatteryData.batteryLevel)")
            }
        default: break
        }
    }
}
