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
        // The device type is taken from the service with the highest priority, the other services add their sensors.
        if let serviceUUID = Device.sensorServiceUUIDs.first(where: { serviceUUID in uuids.contains { Device.isService(serviceUUID, matching: $0) } }),
           let device = makeDevice(forService: serviceUUID) {
            device.addSensors(forServices: uuids)
            return device
        }
        for uuid in uuids where OBDVehicleMetricsDevice.getServicesUUID.contains(where: { $0.lowercased() == uuid.lowercased() }) {
            return OBDVehicleMetricsDevice()
        }
        return nil
    }

    private static func makeDevice(forService serviceUUID: String) -> Device? {
        switch serviceUUID {
        case BLEHeartRateDevice.getServiceUUID: return BLEHeartRateDevice()
        case BLETemperatureDevice.getServiceUUID: return BLETemperatureDevice()
        case BLEBikeSCDDevice.getServiceUUID: return BLEBikeSCDDevice()
        case BLERunningSCDDevice.getServiceUUID: return BLERunningSCDDevice()
        default: return nil
        }
    }

    static func makeOBDSimulatorDevice() -> OBDSimulatorVehicleMetricsDevice {
        OBDSimulatorVehicleMetricsDevice()
    }
}
