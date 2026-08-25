//
//  OBDVehicleMetricsSensor.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 14.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class OBDVehicleMetricsSensor: Sensor {
    var isProcessingReading = false
    
    private(set) var buffer = Data()
    private(set) var stringResponse = ""
    private(set) var isReadyBufferResponse = false

    override func update(with characteristic: CBCharacteristic, result: @escaping (Result<Void, Error>) -> Void) {
        guard let data = characteristic.value else { return }

        switch characteristic.uuid {
        case "2AF0".CBUUIDRepresentation, "2AF1".CBUUIDRepresentation, "FFE1".CBUUIDRepresentation:
            processReceivedData(data, result: result)
        case "FFF1".CBUUIDRepresentation:
            debugPrint("[OBDVehicleMetricsSensor] -> for reading")
        default:
            debugPrint("[OBDVehicleMetricsSensor] -> Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }

    func clearBuffer() {
        NSLog("[OBDVehicleMetricsSensor] -> clearBuffer start")
        isReadyBufferResponse = false
        isProcessingReading = false
        buffer.removeAll()
        stringResponse = ""
        NSLog("[OBDVehicleMetricsSensor] -> clearBuffer end")
    }

    func processReceivedData(_ data: Data, result: @escaping (Result<Void, Error>) -> Void) {
        let previousBufferSize = buffer.count
        buffer.append(data)
        let loggableChunk = String(decoding: data, as: UTF8.self)
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n")
        NSLog("[OBDVehicleMetricsSensor] -> processReceivedData received | chunkBytes: \(data.count) | bufferBytes: \(previousBufferSize) -> \(buffer.count) | chunk: \(loggableChunk)")
        
        guard var string = String(data: buffer, encoding: .utf8) else {
            let bufferHex = buffer.map { String(format: "%02X", $0) }.joined(separator: " ")
            NSLog("[OBDVehicleMetricsSensor] -> processReceivedData invalid UTF-8 | bufferHex: \(bufferHex) | clearing bufferBytes: \(buffer.count)")
            clearBuffer()
            return
        }
        string = string.replacingOccurrences(of: "\r", with: "")
        let loggableResponse = string.replacingOccurrences(of: "\n", with: "\\n")
        
        if string.contains(">") {
            let previousResponseSize = stringResponse.utf8.count
            NSLog("[OBDVehicleMetricsSensor] -> processReceivedData prompt received | response: \(loggableResponse)")
            appendObdResponse(string)
            NSLog("[OBDVehicleMetricsSensor] -> processReceivedData response appended | responseBytes: \(previousResponseSize) -> \(stringResponse.utf8.count)")
            result(.success(()))
            isReadyBufferResponse = true
            NSLog("[OBDVehicleMetricsSensor] -> processReceivedData completed | isReadyBufferResponse: \(isReadyBufferResponse)")
        } else {
            NSLog("[OBDVehicleMetricsSensor] -> processReceivedData waiting for prompt | bufferBytes: \(buffer.count) | response: \(loggableResponse)")
        }
    }

    func readObdBuffer() -> String {
        stringResponse
    }
    
    @objc func writeObdBuffer(string: String) {
        stringResponse = string
    }
    
    private func appendObdResponse(_ response: String) {
        stringResponse += response
    }
}
