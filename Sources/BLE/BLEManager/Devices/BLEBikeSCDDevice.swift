//
//  BLEBikeSCDDevice.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 24.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import CoreBluetooth

final class BLEBikeSCDDevice: Device {
    
    override class var getServiceUUID: String {
        GattAttributes.SERVICE_CYCLING_SPEED_AND_CADENCE
    }
    
    override init() {
        super.init()
        deviceType = .BLE_BICYCLE_SCD
        sensors.append(BLEBikeSensor())
    }
    
    override var getServiceConnectedImage: UIImage {
        UIImage(named: "widget_sensor_bicycle_power")!
    }
    
    override var getDataFields: Dictionary<String, String>? {
        if let sensor = sensors.first(where: { $0 is BLEBikeSensor }) as? BLEBikeSensor {
            var dic = [String: String]()
            dic["Speed"] = String(sensor.lastBikeSpeedDistanceData.speed)
            dic["Cadence"] = String(sensor.lastBikeCadenceData.cadence)
//            if let lastBikeSpeedDistanceData = sensor.lastBikeSpeedDistanceData {
//                dic["Speed"] = String(sensor.lastBikeSpeedDistanceData.speed)
//            }
//            if let lastBikeCadenceData = sensor.lastBikeCadenceData {
//                dic["Speed"] = String(sensor.lastBikeSpeedDistanceData.speed)
//                dic["Cadence"] = String(sensor.lastBikeCadenceData.cadence)
//            }
            return dic.isEmpty ? nil : dic
            
    
            //    CHARACTERISTIC_CYCLING_SPEED_AND_CADENCE_MEASUREMENT
           // return ["Unknow": String(sensor.heartRateData.heartRate)]
        }
        return nil
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
//        guard characteristic.service?.uuid == GattAttributes.SERVICE_CYCLING_SPEED_AND_CADENCE.CBUUIDRepresentation else {
//            return
//        }
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

