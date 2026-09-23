//
//  DeviceFactory.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 12.10.2023.
//

import Foundation

final class DeviceFactory {
    static func createDevice(with uuids: [String]) -> Device? {
        // A sensor can advertise several services (Garmin HRM 600: running speed and cadence + heart rate).
        // The device type is taken from the service with the highest priority, not from the advertisement order.
        func hasService(_ serviceUUID: String) -> Bool {
            uuids.contains { serviceUUID.contains($0) }
        }
        if hasService(BLEHeartRateDevice.getServiceUUID) {
            return BLEHeartRateDevice()
        }
        if hasService(BLETemperatureDevice.getServiceUUID) {
            return BLETemperatureDevice()
        }
        if hasService(BLEBikeSCDDevice.getServiceUUID) {
            return BLEBikeSCDDevice()
        }
        if hasService(BLERunningSCDDevice.getServiceUUID) {
            return BLERunningSCDDevice()
        }
        for uuid in uuids where OBDVehicleMetricsDevice.getServicesUUID.contains(where: { $0.lowercased() == uuid.lowercased() }) {
            return OBDVehicleMetricsDevice()
        }
        return nil
    }
    
    static func makeOBDSimulatorDevice() -> OBDSimulatorVehicleMetricsDevice {
        OBDSimulatorVehicleMetricsDevice()
    }
}
