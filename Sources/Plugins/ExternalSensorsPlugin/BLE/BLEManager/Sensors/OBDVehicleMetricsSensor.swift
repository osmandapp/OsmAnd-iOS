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
  

//    private let syncQueue = DispatchQueue(label: "com.osmand.vehicleMetricsSensor", attributes: .concurrent)

//    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
//        [.bicycleCadence, .bicycleSpeed, .bicycleDistance]
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
      //  syncQueue.async(flags: .barrier) {
            NSLog("[OBDVehicleMetricsSensor] -> clearBuffer start")
            self.isReadyBufferResponse = false
            self.isProcessingReading = false
            self.buffer.removeAll()
            self.stringResponse = ""
        NSLog("[OBDVehicleMetricsSensor] -> clearBuffer end")
      //  }
    }

    func processReceivedData(_ data: Data, result: @escaping (Result<Void, Error>) -> Void) {
        print("processReceivedData 1")
     //   syncQueue.async(flags: .barrier) {
            buffer.append(data)

            guard var string = String(data: buffer, encoding: .utf8) else {
                clearBuffer()
                return
            }
            string = string.replacingOccurrences(of: "\r", with: "")

            if string.contains(">") {
                print("processReceivedData 2")
//                var lines = string
//                    .components(separatedBy: .newlines)
//                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
//                lines.removeLast()

                appendObdResponse(string)
                print("processReceivedData 3")

              //  DispatchQueue.main.async {
                    result(.success(()))
             //   }

               // #if DEBUG
                NSLog("processReceivedData OBD -> Response: \(string)")
                isReadyBufferResponse = true
              //  #endif
            }
        }

func readObdBuffer() -> String {
//    if !stringResponse.isEmpty {
//        print("readObdBuffer: \(self.stringResponse)")
//    }
    
    return stringResponse
//        var result: String?
//        syncQueue.sync {
//            result = self.stringResponse.isEmpty ? nil : self.stringResponse
//        }
//        return result
    }

    @objc func writeObdBuffer(string: String) {
//        print("writeObdBuffer value: \(string)")
//        print("writeObdBuffer before: \(self.stringResponse)")
     //   syncQueue.async(flags: .barrier) {
        self.stringResponse = string
      //  print("writeObdBuffer after: \( self.stringResponse)")
     //   }
    }
    
    private func appendObdResponse(_ response: String) {
      //  print("appendObdResponse before: \(self.stringResponse)")
      //  syncQueue.async(flags: .barrier) {
            self.stringResponse += response
        
      //  print("appendObdResponse after: \(self.stringResponse)")
      //  }
    }
}


//final class OBDVehicleMetricsSensor: Sensor {
//    
//    private(set) var buffer = Data()
//    private(set) var stringResponse = ""
//    private(set) var isReadyBufferResponse = false
//    
////    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
////        return [.bicycleCadence, .bicycleSpeed, .bicycleDistance]
////    }
//    
//    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
//        guard let data = characteristic.value else { return }
//
//        switch characteristic.uuid {
//        case "2AF0".CBUUIDRepresentation,
//             "2AF1".CBUUIDRepresentation,
//             "FFE1".CBUUIDRepresentation:
//            processReceivedData(data, result: result)
//        case "FFF1".CBUUIDRepresentation:
//            print("[OBDVehicleMetricsSensor] -> Received read-only characteristic.")
//        default:
//            debugPrint("[OBDVehicleMetricsSensor] -> Unhandled UUID: \(characteristic.uuid)")
//        }
//    }
//    
//    func clearBuffer() {
//        NSLog("[OBDVehicleMetricsSensor] -> clearBuffer")
//        isReadyBufferResponse = false
//        buffer.removeAll()
//        stringResponse = ""
//    }
//    
//    func processReceivedData(_ data: Data, result: (Result<Void, Error>) -> Void) {
//        buffer.append(data)
//
//        guard let fullString = String(data: buffer, encoding: .utf8) else {
//            clearBuffer()
//            result(.failure(OBDError.invalidEncoding))
//            return
//        }
//
//        guard fullString.contains(">") else { return }
//
//     //   if !lines.isEmpty {
//            appendObdResponse(fullString)
//            isReadyBufferResponse = true
//            result(.success(()))
//            #if DEBUG
//        let lines = fullString
//            .components(separatedBy: .newlines)
//            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
//            .filter { !$0.isEmpty }
//            debugPrint("[OBDVehicleMetricsSensor] -> Response lines: \(lines)")
//            #endif
//    //    }
//    }
//
//    @objc func readObdBuffer() -> String? {
//        return stringResponse.isEmpty ? nil : stringResponse
//    }
//
//    @objc func writeObdBuffer(string: String) {
//        stringResponse = string
//    }
//
//    private func appendObdResponse(_ response: String) {
//        stringResponse += response
//    }
//}
//
//// Optional: Custom error for better context
//enum OBDError: Error {
//    case invalidEncoding
//}


//final class OBDVehicleMetricsSensor: Sensor {
//    private(set) var buffer = Data()
//    private(set) var stringResponse: String = ""
//    var isReadyBufferResponse = false
//    
////    private(set) var lastRunningCadenceData: RunningCadenceData?
////    private(set) var lastRunningSpeedData: RunningSpeedData?
////    private(set) var lastRunningDistanceData: RunningDistanceData?
////    private(set) var lastRunningStrideLengthData: RunningStrideLengthData?
//    
////    override func getLastSensorDataList(for widgetType: WidgetType) -> [SensorData]? {
////        if widgetType == .bicycleCadence {
////            return [lastRunningCadenceData].compactMap { $0 }
////        } else if widgetType == .bicycleSpeed {
////            return [lastRunningSpeedData].compactMap { $0 }
////        } else if widgetType == .bicycleDistance {
////            return [lastRunningDistanceData].compactMap { $0 }
////        }
////        return nil
////    }
//    
//    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
//        [.bicycleCadence, .bicycleSpeed, .bicycleDistance]
//    }
//    
//    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
//        guard let data = characteristic.value else {
//            return
//        }
//
//        switch characteristic.uuid {
//        case "2AF0".CBUUIDRepresentation:
//            processReceivedData(data, result: result)
//        case "2AF1".CBUUIDRepresentation:
//            processReceivedData(data, result: result)
//        case "FFE1".CBUUIDRepresentation:
//            processReceivedData(data, result: result)
//        case "FFF1".CBUUIDRepresentation:
//            print("for reading")
//        default:
//            debugPrint("Unhandled Characteristic UUID: \(characteristic.uuid)")
//        }
//    }
//    
//    func clearBuffer() {
//        NSLog("[OBDVehicleMetricsSensor] -> clearBuffer")
//        isReadyBufferResponse = false
//        buffer.removeAll()
//        stringResponse = ""
//    }
//    
//    func processReceivedData(_ data: Data, result: (Result<Void, Error>) -> Void) {
//        buffer.append(data)
//
//        guard let string = String(data: buffer, encoding: .utf8) else {
//            clearBuffer()
//            return
//        }
//
//        if string.contains(">") {
//            var lines = string
//                .components(separatedBy: .newlines)
//                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
//            lines.removeLast()
//            // FIXME:
//           // let normalized = string.replacingOccurrences(of: "\r", with: "")
//            appendObdResponse(string)
//            isReadyBufferResponse = true
//
//            result(.success)
//            #if DEBUG
//            NSLog("processReceivedData OBD -> Response: \(lines)")
//           // processReceivedData OBD -> Response: ["SEARCHING...", "7E906410098188013", "7E8064100BE3EB81B"]
//           // processReceivedData OBD -> Response: ["SEARCHING...", "UNABLE TO CONNECT"]
//            #endif
//        }
//    }
//    
//    @objc func readObdBuffer() -> String? {
//        stringResponse.isEmpty ? nil : stringResponse
//    }
//    
//    @objc func writeObdBuffer(string: String) {
//        stringResponse = string
//    }
//    
//    private func appendObdResponse(_ response: String) {
//        stringResponse += response
//    }
//}
