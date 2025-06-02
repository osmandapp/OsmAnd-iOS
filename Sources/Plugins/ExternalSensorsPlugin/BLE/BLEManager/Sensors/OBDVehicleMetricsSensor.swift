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
  
//    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
//        []
//    }

    override func update(with characteristic: CBCharacteristic, result: @escaping (Result<Void, Error>) -> Void) {
        guard let data = characteristic.value else { return }

        switch characteristic.uuid {
        case "2AF0".CBUUIDRepresentation, "2AF1".CBUUIDRepresentation, "FFE1".CBUUIDRepresentation:
            processReceivedData(data, result: result)
        case "FFF1".CBUUIDRepresentation:
            print("for reading")
        default:
            debugPrint("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }

    func clearBuffer() {
        NSLog("[OBDVehicleMetricsSensor] -> clearBuffer start")
        self.isReadyBufferResponse = false
        self.isProcessingReading = false
        self.buffer.removeAll()
        self.stringResponse = ""
        NSLog("[OBDVehicleMetricsSensor] -> clearBuffer end")
    }

    func processReceivedData(_ data: Data, result: @escaping (Result<Void, Error>) -> Void) {
        print("processReceivedData 1")
        buffer.append(data)
        
        guard var string = String(data: buffer, encoding: .utf8) else {
            clearBuffer()
            return
        }
        string = string.replacingOccurrences(of: "\r", with: "")
        
        if string.contains(">") {
            print("processReceivedData 2")
            appendObdResponse(string)
            print("processReceivedData 3")
            result(.success(()))
            NSLog("processReceivedData OBD -> Response: \(string)")
            isReadyBufferResponse = true
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
