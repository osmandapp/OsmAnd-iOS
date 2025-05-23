//
//  ELM327Adapter.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 19.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import CoreBluetooth

enum ELM327Error: Error, LocalizedError {
    case noProtocolFound
    case invalidResponse(message: String)
    case adapterInitializationFailed
    case ignitionOff
    case invalidProtocol
    case timeout
    case connectionFailed(reason: String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .noProtocolFound:
            return "No compatible OBD protocol found."
        case let .invalidResponse(message):
            return "Invalid response received: \(message)"
        case .adapterInitializationFailed:
            return "Failed to initialize adapter."
        case .ignitionOff:
            return "Vehicle ignition is off."
        case .invalidProtocol:
            return "Invalid or unsupported OBD protocol."
        case .timeout:
            return "Operation timed out."
        case let .connectionFailed(reason):
            return "Connection failed: \(reason)"
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}

final class ELM327Adapter {
    private let service: CommProtocol
    
    var canProtocol: CANProtocol?
    private var r100: [String] = []
    
    init(service: CommProtocol) {
        self.service = service
    }
    
    func adapterInitialization() async throws {
        NSLog("[ELM327Adapter] -> Initializing ELM327 adapter...")
        do {
            _ = try await sendCommand("ATZ") // Reset adapter
            _ = try await okResponse("ATE0") // Echo off
            _ = try await okResponse("ATL0") // Linefeeds off
            _ = try await okResponse("ATS0") // Spaces off
            _ = try await okResponse("ATH1") // Headers off
            _ = try await okResponse("ATSP0") // Set protocol to automatic
            NSLog("[ELM327Adapter] -> ELM327 adapter initialized successfully.")
        } catch {
            NSLog("[ELM327Adapter] -> Adapter initialization failed: \(error.localizedDescription)")
            throw ELM327Error.adapterInitializationFailed
        }
    }
    
    func sendCommand(_ message: String, retries: Int = 1) async throws -> [String] {
        try await service.sendCommand(message, retries: retries)
    }
    
    func requestVin() async -> String? {
        let command = OBDCommand.Mode9.VIN
        guard let vinResponse = try? await sendCommand(command.properties.command) else {
            return nil
        }

        guard let data = try? canProtocol?.parse(vinResponse).first?.data,
              var vinString = String(bytes: data, encoding: .utf8)
        else {
            return nil
        }

        vinString = vinString
            .replacingOccurrences(of: "[^a-zA-Z0-9]",
                                  with: "",
                                  options: .regularExpression)

        return vinString
    }
    
    func setupVehicle(preferredProtocol: PROTOCOL?) async throws -> OBDInfo {
        let detectedProtocol = try await detectProtocol(preferredProtocol: preferredProtocol)

        canProtocol = protocols[detectedProtocol]

        let vin = await requestVin()

//        let supportedPIDs = await getSupportedPIDs()
//
//        guard let messages = try canProtocol?.parse(r100) else {
//            throw ELM327Error.invalidResponse(message: "Invalid response to 0100")
//        }
//
//        let ecuMap = populateECUMap(messages)
//
//        connectionState = .connectedToVehicle
        return OBDInfo(vin: vin)
    }
    
    private func detectProtocol(preferredProtocol: PROTOCOL? = nil) async throws -> PROTOCOL {
        NSLog("[ELM327Adapter] -> Starting protocol detection...")

        if let preferredProtocol {
            NSLog("[ELM327Adapter] -> Attempting preferred protocol: \(preferredProtocol.description)")
            if await testProtocol(preferredProtocol) {
                return preferredProtocol
            } else {
                NSLog("[ELM327Adapter] -> Preferred protocol \(preferredProtocol.description) failed. Falling back to automatic detection.")
            }
        } else {
//            do {
//                return try await detectProtocolAutomatically()
//            } catch {
//                return try await detectProtocolManually()
//            }
        }

        NSLog("[ELM327Adapter] -> Failed to detect a compatible OBD protocol.")
        throw ELM327Error.noProtocolFound
    }
    
    private func testProtocol(_ obdProtocol: PROTOCOL) async -> Bool {
        // test protocol by sending 0100 and checking for 41 00 response
        let response = try? await sendCommand("0100", retries: 3)

        if let response,
           response.contains(where: { $0.range(of: #"41\s*00"#, options: .regularExpression) != nil }) {
            NSLog("[ELM327Adapter] -> Protocol \(obdProtocol.description) is valid.")
            r100 = response
            return true
        } else {
            NSLog("[ELM327Adapter] -> Protocol \(obdProtocol.rawValue) did not return valid 0100 response.")
            return false
        }
    }
    
    private func okResponse(_ message: String) async throws -> [String] {
        let response = try await sendCommand(message)
        if response.contains("OK") {
            return response
        } else {
            NSLog("[ELM327Adapter] -> Invalid response: \(response)")
            throw ELM327Error.invalidResponse(message: "message: \(message), \(String(describing: response.first))")
        }
    }
}

struct BatchedResponse {
    private var response: Data
    private var unit: MeasurementUnit
    init(response: Data, _ unit: MeasurementUnit) {
        self.response = response
        self.unit = unit
    }

    mutating func extractValue(_ cmd: OBDCommand) -> MeasurementResult? {
        let properties = cmd.properties
        let size = properties.bytes
        guard response.count >= size else { return nil }
        let valueData = response.prefix(size)

        response.removeFirst(size)
        //        print("Buffer: \(buffer.compactMap { String(format: "%02X ", $0) }.joined())")
        let result = cmd.properties.decode(data: valueData, unit: unit)

        switch result {
        case let .success(measurementResult):
            return measurementResult.measurementResult
        case let .failure(error):
            NSLog("[BatchedResponse] -> Failed to decode \(cmd.properties.command): \(error.localizedDescription)")
            return nil
        }
    }
}
