//
//  OBDVehicleMetricsSensor.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 14.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class OBDVehicleMetricsSensor: Sensor {
    private(set) var buffer = Data()
    private(set) var stringResponse: String = ""
    var isReadyBufferResponse = false
    
//    private(set) var lastRunningCadenceData: RunningCadenceData?
//    private(set) var lastRunningSpeedData: RunningSpeedData?
//    private(set) var lastRunningDistanceData: RunningDistanceData?
//    private(set) var lastRunningStrideLengthData: RunningStrideLengthData?
    
//    override func getLastSensorDataList(for widgetType: WidgetType) -> [SensorData]? {
//        if widgetType == .bicycleCadence {
//            return [lastRunningCadenceData].compactMap { $0 }
//        } else if widgetType == .bicycleSpeed {
//            return [lastRunningSpeedData].compactMap { $0 }
//        } else if widgetType == .bicycleDistance {
//            return [lastRunningDistanceData].compactMap { $0 }
//        }
//        return nil
//    }
    
    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        [.bicycleCadence, .bicycleSpeed, .bicycleDistance]
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        guard let data = characteristic.value else {
            return
        }

        switch characteristic.uuid {
        case "2AF0".CBUUIDRepresentation:
            processReceivedData(data, result: result)
        case "2AF1".CBUUIDRepresentation:
            processReceivedData(data, result: result)
        case "FFE1".CBUUIDRepresentation:
            processReceivedData(data, result: result)
        case "FFF1".CBUUIDRepresentation:
            print("for reading")
        default:
            debugPrint("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    func clearBuffer() {
        isReadyBufferResponse = false
        buffer.removeAll()
        stringResponse = ""
    }
    
    func processReceivedData(_ data: Data, result: (Result<Void, Error>) -> Void) {
        buffer.append(data)

        guard let string = String(data: buffer, encoding: .utf8) else {
            clearBuffer()
            return
        }

        if string.contains(">") {
            var lines = string
                .components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            lines.removeLast()
            // FIXME:
           // let normalized = string.replacingOccurrences(of: "\r", with: "")
            appendObdResponse(string)
            isReadyBufferResponse = true

            result(.success)
            #if DEBUG
            NSLog("processReceivedData OBD -> Response: \(lines)")
           // processReceivedData OBD -> Response: ["SEARCHING...", "7E906410098188013", "7E8064100BE3EB81B"]
           // processReceivedData OBD -> Response: ["SEARCHING...", "UNABLE TO CONNECT"]
            #endif
        }
    }
    
    @objc func readObdBuffer() -> String? {
        stringResponse.isEmpty ? nil : stringResponse
    }
    
    @objc func writeObdBuffer(string: String) {
        stringResponse = string
    }
    
    private func appendObdResponse(_ response: String) {
        stringResponse += response
    }
}
