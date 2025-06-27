//
//  OBDVehicleMetricsDevice.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 14.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class OBDVehicleMetricsDevice: Device {
    
    var ecuWriteCharacteristic: CBCharacteristic?
    
    override var deviceServiceName: String {
        "OBD Sensor"
    }
    
    class var getServicesUUID: [String] {
        ["FFE0", "FFF0", "18F0"]
    }
    
    override var getServiceConnectedImage: UIImage? {
        .widgetObdCar
    }
    
    override var getServiceDisconnectedImage: UIImage? {
        .icCustomCarObd2
    }
    
    init() {
        super.init(deviceType: .OBD_VEHICLE_METRICS)
        sensors.append(OBDVehicleMetricsSensor(device: self, sensorId: "vehicle_sensor"))
    }
    
    override func discoverCharacteristics(withUUIDs characteristicUUIDs: [CBUUIDConvertible]? = nil,
                                 ofServiceWithUUID serviceUUID: CBUUIDConvertible,
                                 completion: @escaping CharacteristicRequestCallback) {
        peripheral.discoverCharacteristics(withUUIDs: characteristicUUIDs,
                                           ofServiceWithUUID: serviceUUID,
                                           completion: { [weak self] result in
            if case .success(let characteristics) = result {
                for characteristic in characteristics {
                    switch characteristic.uuid.uuidString {
                    case "FFE1": // for servcice FFE0
                        self?.ecuWriteCharacteristic = characteristic
                    case "FFF1": // for servcice FFF0
                        print("FFF1 reading characteristic")
                    case "2AF0": // for servcice 18F0
                        print("2AF0 reading characteristic")
                    case "FFF2": // for servcice FFF0
                        self?.ecuWriteCharacteristic = characteristic
                    case "2AF1": // for servcice 18F0
                        self?.ecuWriteCharacteristic = characteristic
                    default:
                        break
                    }
                }
            }
            completion(result)
        })
    }
    
    override func disconnect(completion: @escaping DisconnectPeripheralCallback) {
        peripheral.disconnect(completion: { [weak self] result in
            if case .success = result {
                self?.ecuWriteCharacteristic = nil
            }
            completion(result)
        })
    }
    
    override func update(with characteristic: CBCharacteristic, result: @escaping (Result<Void, Error>) -> Void) {
        sensors.forEach { $0.update(with: characteristic, result: result) }
    }
    
    override func notifyRSSI() { }
    
    override func disableRSSI() { }
    
}
