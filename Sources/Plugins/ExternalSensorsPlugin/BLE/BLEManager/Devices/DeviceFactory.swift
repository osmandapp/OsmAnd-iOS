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
            if BLETemperatureDevice.getServiceUUID.contains(uuid) {
                return BLETemperatureDevice()
            }
            if BLEBikeSCDDevice.getServiceUUID.contains(uuid) {
                return BLEBikeSCDDevice()
            }
            if BLERunningSCDDevice.getServiceUUID.contains(uuid) {
                return BLERunningSCDDevice()
            }
            if OBDVehicleMetricsDevice.getServicesUUID.contains(where: { $0.lowercased() == uuid.lowercased() }) {
                return OBDVehicleMetricsDevice()
            }
        }
        return nil
    }
    
    static func makeOBDSimulatorDevice() -> OBDSimulatorVehicleMetricsDevice {
        OBDSimulatorVehicleMetricsDevice()
    }
}
