//
//  OBDVehicleMetricsDevice.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 14.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class OBDVehicleMetricsDevice: Device {

    private(set) var ecuWriteCharacteristic: CBCharacteristic?
    private(set) var ecuReadCharacteristic: CBCharacteristic?

    var ecuWriteType: CBCharacteristicWriteType {
        ecuWriteCharacteristic?.properties.contains(.write) == true ? .withResponse : .withoutResponse
    }

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
    
    // Call once the characteristics of all services are discovered.
    // As on Android, the channel is chosen by characteristic properties, not fixed UUIDs:
    // adapters differ in which characteristic notifies and which accepts writes.
    func setupOBDChannel(completion: @escaping (Bool) -> Void) {
        let services = peripheral.services ?? []
        for serviceUUID in Self.getServicesUUID {
            guard let service = services.first(where: { $0.uuid == CBUUID(string: serviceUUID) }),
                  let characteristics = service.characteristics,
                  let readCharacteristic = characteristics.first(where: { $0.properties.contains(.notify) }),
                  let writeCharacteristic = characteristics.first(where: { $0.properties.contains(.write) || $0.properties.contains(.writeWithoutResponse) }) else {
                continue
            }
            ecuReadCharacteristic = readCharacteristic
            ecuWriteCharacteristic = writeCharacteristic
            NSLog("[OBDVehicleMetricsDevice] -> setupOBDChannel | service: \(service.uuid) | read: \(readCharacteristic.uuid) | write: \(writeCharacteristic.uuid)")
            setNotifyValue(toEnabled: true, ofCharac: readCharacteristic) { result in
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    NSLog("[OBDVehicleMetricsDevice] -> setupOBDChannel enable notify failure: \(error.localizedDescription)")
                    completion(false)
                }
            }
            return
        }
        NSLog("[OBDVehicleMetricsDevice] -> setupOBDChannel no service with notify and write characteristics | services: \(services.map(\.uuid))")
        completion(false)
    }

    override func disconnect(completion: @escaping DisconnectPeripheralCallback) {
        peripheral.disconnect(completion: { [weak self] result in
            if case .success = result {
                self?.ecuWriteCharacteristic = nil
                self?.ecuReadCharacteristic = nil
            }
            completion(result)
        })
    }

    func isECUReadCharacteristic(_ characteristic: CBCharacteristic) -> Bool {
        guard let ecuReadCharacteristic else { return false }
        return characteristic.uuid == ecuReadCharacteristic.uuid
            && characteristic.service?.uuid == ecuReadCharacteristic.service?.uuid
    }

    override func update(with characteristic: CBCharacteristic, result: @escaping (Result<Void, Error>) -> Void) {
        sensors.forEach { $0.update(with: characteristic, result: result) }
    }
    
    override func notifyRSSI() { }
    
    override func disableRSSI() { }
}

final class OBDSimulatorVehicleMetricsDevice: OBDVehicleMetricsDevice {
    
    static let simulatorId = "simulator_OBD"
    
    override var id: String { Self.simulatorId }
    
    override var state: DeviceState {
        plugin?.isOBDSimulatorConnected == true ? .connected : .disconnected
    }
    
    override var isConnected: Bool {
        plugin?.isOBDSimulatorConnected == true
    }
    
    override var isConnecting: Bool { false }
    
    private var simulationTimer: Timer?
    
    private var plugin: VehicleMetricsPlugin? {
        OAPluginsHelper.getEnabledPlugin(VehicleMetricsPlugin.self) as? VehicleMetricsPlugin
    }
    
    override func connect(withTimeout timeout: TimeInterval?, completion: @escaping ConnectPeripheralCallback) {
        guard let plugin else {
            completion(.failure(SimulatorError.unableToConnect))
            return
        }
        
        plugin.isOBDSimulatorConnected = true
        completion(.success)
        OBDService.shared.startDispatcher(isSimulator: true)
        startSimulationTimer()
    }
    
    override func disconnect(completion: @escaping DisconnectPeripheralCallback) {
        guard let plugin else {
            completion(.failure(SimulatorError.unableToDisconnect))
            return
        }
        
        plugin.isOBDSimulatorConnected = false
        OBDService.shared.stopDispatcher()
        stopSimulationTimer()
        completion(.success)
    }
    
    override init() {
        super.init()
        isSimulator = true
        deviceName = "Simulation Device"
    }
    
    // MARK: - Simulation Timer
    
    private func startSimulationTimer() {
        stopSimulationTimer()
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.performSimulationTick()
        }
        RunLoop.main.add(timer, forMode: .common)
        simulationTimer = timer
    }
    
    private func stopSimulationTimer() {
        simulationTimer?.invalidate()
        simulationTimer = nil
    }
    
    private func performSimulationTick() {
        didChangeCharacteristic?()
    }
    
    deinit {
        stopSimulationTimer()
    }
}

// MARK: - Simulator Errors

private enum SimulatorError: Error {
    case unableToConnect, unableToDisconnect
    
    var errorDescription: String? {
        switch self {
        case .unableToConnect: "Failed to connect to the OBD simulator."
        case .unableToDisconnect: "Failed to disconnect from the OBD simulator."
        }
    }
}
