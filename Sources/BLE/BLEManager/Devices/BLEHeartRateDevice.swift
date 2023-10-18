//
//  BLEHeartRateDevice.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 12.10.2023.
//

import Foundation
import CoreBluetooth
import UIKit

final class BLEHeartRateDevice: Device {
    
    override class var getServiceUUID: String {
        GattAttributes.SERVICE_HEART_RATE
    }
    
    override init() {
        super.init()
        deviceType = .BLE_HEART_RATE
        sensors.append(BLEHeartRateSensor())
    }
    
    override var getServiceConnectedImage: UIImage {
        UIImage(named: "widget_sensor_heart_rate")!
    }
    
    override var getDataFields: Dictionary<String, String>? {
        if let sensor = sensors.first(where: { $0 is BLEHeartRateSensor }) as? BLEHeartRateSensor {
            return ["HEART_RATE": String(sensor.heartRateData.heartRate)]
        }
        return nil
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        guard characteristic.service?.uuid == GattAttributes.SERVICE_HEART_RATE.CBUUIDRepresentation else {
            return
        }
        sensors.forEach{ $0.update(with: characteristic, result: result)}
    }
    
//    public List<SensorDataField> getDataFields() {
//            return Collections.singletonList(
//                    new SensorDataField(R.string.map_widget_ant_heart_rate, R.string.beats_per_minute_short, heartRate));
//        }
    
    
    
//    public BLEHeartRateDevice(@NonNull BluetoothAdapter bluetoothAdapter, @NonNull String deviceId) {
//        super(bluetoothAdapter, deviceId);
//        sensors.add(new BLEHeartRateSensor(this));
//    }
//
//    @NonNull
//    @Override
//    public DeviceType getDeviceType() {
//        return DeviceType.BLE_HEART_RATE;
//    }
//
//    @NonNull
//    public static UUID getServiceUUID() {
//        return GattAttributes.UUID_SERVICE_HEART_RATE;
//    }
    
}
