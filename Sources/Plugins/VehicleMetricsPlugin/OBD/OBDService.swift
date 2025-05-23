//
//  OBDService.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 21.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

struct OBDInfo: Codable, Hashable {
    var vin: String?
}

enum OBDServiceError: Error {
    //case noAdapterFound
 //   case notConnectedToVehicle
//    case adapterConnectionFailed(underlyingError: Error)
//    case scanFailed(underlyingError: Error)
 //   case clearFailed(underlyingError: Error)
    case failAdapterInitialization
    case commandFailed(command: String, error: Error)
}

final class OBDService {
    static let shared = OBDService()
    
    let vehicleMetricsCommandsFullList: [OBDCommand] = [
        .mode1(.rpm),
        .mode1(.speed),
        .mode1(.intakeTemp),
        .mode1(.ambientAirTemp),
        .mode1(.coolantTemp),
        .mode1(.engineOilTemp),
        .mode1(.engineLoad),
        .mode1(.fuelPressure),
        .mode1(.throttlePos),
        .mode1(.controlModuleVoltage),
        .mode1(.fuelType),
        .mode1(.fuelRate),
        .mode1(.fuelLevel)
    ]
    
    lazy var elm327Adapter: ELM327Adapter = ELM327Adapter(service: BLEManager.shared)
    
    private(set) var obdInfo: OBDInfo?
    
    private var timer: Timer?
    private var isUpdating = false
    
    private init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeviceDisconnected),
                                               name: .DeviceDisconnected,
                                               object: nil)
    }
    
    func adapterInitialization() async throws -> OBDInfo? {
        do {
            try await elm327Adapter.adapterInitialization()
            // TODO: save preferredProtocol to OBD Device (.protocol6) for old cars
            obdInfo = try await elm327Adapter.setupVehicle(preferredProtocol: .protocol6)
            return obdInfo
        } catch {
            throw OBDServiceError.failAdapterInitialization
        }
    }
    
    func startDispatcher() {
        let dispatch = OBDDispatcher(debug: false)
        OBDDataComputer.shared.obdDispatcher = dispatch
        OBDDataComputer.OBDTypeWidget.entries.forEach { widget in
            OBDDataComputer.shared.registerWidget(type: widget, averageTimeSeconds: 0)
        }

        dispatch.connect(connector: OATestOBDConnector())
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            OBDDataComputer.shared.widgets.forEach { widget in
//                let localizeTitle = widget.type.getTitle()
//            //   let localizeTitle = OBDDataComputer.OBDTypeWidget.rpm.getTitle()
//               // icons
//              // let localizeTitle = OBDDataComputer.OBDTypeWidget.rpm.g
//               // widget.type == OBDDataComputer.OBDTypeWidget.rpm
//              // let value = widget.computeValue()
//            }
//        }
    }
    
    func startContinuousUpdates(pids: [OBDCommand],
                                unit: MeasurementUnit = .metric,
                                interval: TimeInterval = 0.3) {
        guard !isUpdating else { return }
        isUpdating = true
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.updatePIDs(pids, unit: unit)
            }
        }
    }
    
    func stopContinuousUpdates() {
        guard isUpdating else { return }

        timer?.invalidate()
        timer = nil
        isUpdating = false
    }
    
    private func updatePIDs(_ pids: [OBDCommand], unit: MeasurementUnit) async {
        do {
            let results = try await requestPIDs(pids, unit: unit)
            updateResults(measurements: results)
        } catch {
            NSLog("[OBDService] -> Failed to update PIDs: \(error)")
        }
    }
    
    private func updateResults(measurements: [OBDCommand: MeasurementResult]) {
        for (pid, measurement) in measurements {
            print("command: \(pid.properties.command) | description: \(pid.properties.description) ) | value:  \(measurement.value)")
        }
    }
    
    private func requestPIDs(_ commands: [OBDCommand], unit: MeasurementUnit) async throws -> [OBDCommand: MeasurementResult] {
        let response = try await sendCommandInternal("01" + commands.compactMap { $0.properties.command.dropFirst(2) }.joined(), retries: 10)

        guard let responseData = try OBDService.shared.elm327Adapter.canProtocol?.parse(response).first?.data else { return [:] }

        var batchedResponse = BatchedResponse(response: responseData, unit)

        let results: [OBDCommand: MeasurementResult] = commands.reduce(into: [:]) { result, command in
            let measurement = batchedResponse.extractValue(command)
            result[command] = measurement
        }

        return results
    }
    
    private func sendCommandInternal(_ message: String, retries: Int) async throws -> [String] {
        do {
            return try await elm327Adapter.sendCommand(message, retries: retries)
        } catch {
            throw OBDServiceError.commandFailed(command: message, error: error)
        }
    }
    
    @objc private func handleDeviceDisconnected() {
        stopContinuousUpdates()
    }
}
