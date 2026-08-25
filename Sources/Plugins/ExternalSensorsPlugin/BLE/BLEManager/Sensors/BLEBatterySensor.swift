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
    
    var widgetFields: [SensorWidgetDataField]? {
        [SensorWidgetDataField(fieldType: .battery,
                               nameId: localizedString("map_widget_battery"),
                               unitNameId: batteryLevel != -1 ? "%" : "",
                               numberValue: nil,
                               stringValue: batteryLevel != -1 ? String(batteryLevel) : "-")]
    }
    
    func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField? {
        widgetFields?.first
    }
}

final class BLEBatterySensor: Sensor {
    private(set) var lastBatteryData = BatteryData()
    
    override func update(with characteristic: CBCharacteristic, result: @escaping (Result<Void, Error>) -> Void) {
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
    
    override func getLastSensorDataList(for widgetType: WidgetType) -> [SensorData]? {
        [lastBatteryData].compactMap { $0 }
    }
}
