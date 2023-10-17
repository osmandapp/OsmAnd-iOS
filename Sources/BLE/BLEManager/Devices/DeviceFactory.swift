//
//  DeviceFactory.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 12.10.2023.
//

import Foundation

final class DeviceFactory {
    static func createDevice(with uuids: [String]) -> Device? {
        for uuid in uuids {
            if BLEHeartRateDevice.getServiceUUID.contains(uuid) {
                return BLEHeartRateDevice()
            }
        }
        return nil

        /*
         else if (BLETemperatureDevice.getServiceUUID().equals(uuid)) {
             device = new BLETemperatureDevice(bluetoothAdapter, address);
         } else if (BLEBikeSCDDevice.getServiceUUID().equals(uuid)) {
             device = new BLEBikeSCDDevice(bluetoothAdapter, address);
         } else if (BLERunningSCDDevice.getServiceUUID().equals(uuid)) {
             device = new BLERunningSCDDevice(bluetoothAdapter, address);
         } else if (BLEBPICPDevice.getServiceUUID().equals(uuid)) {
             device = new BLEBPICPDevice(bluetoothAdapter, address);
         }
         
         */
    }
}
