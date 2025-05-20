//
//  OBDVehicleMetricsSensor.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 14.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class OBDVehicleMetricsSensor: Sensor {
    private var buffer = Data()
    
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
    
//    func didDiscoverCharacteristics(_ peripheral: CBPeripheral, service: CBService, error _: Error?) {
//        guard let characteristics = service.characteristics, !characteristics.isEmpty else {
//            return
//        }
//
//        for characteristic in characteristics {
//            if characteristic.properties.contains(.notify) {
//                peripheral.setNotifyValue(true, for: characteristic)
//            }
//            switch characteristic.uuid.uuidString {
//            case "FFE1": // for servcice FFE0
//                ecuWriteCharacteristic = characteristic
//                ecuReadCharacteristic = characteristic
//            case "FFF1": // for servcice FFF0
//                ecuReadCharacteristic = characteristic
//            case "FFF2": // for servcice FFF0
//                ecuWriteCharacteristic = characteristic
//            case "2AF0": // for servcice 18F0
//                ecuReadCharacteristic = characteristic
//            case "2AF1": // for servcice 18F0
//                ecuWriteCharacteristic = characteristic
//            default:
//                break
//            }
//        }
//
//        if connectionCompletion != nil, ecuWriteCharacteristic != nil, ecuReadCharacteristic != nil {
//            connectionCompletion?(peripheral, nil)
//        }
//    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        guard let data = characteristic.value else {
            return
        }
        
        // FIXME:
        switch characteristic.uuid {
        case "2AF0".CBUUIDRepresentation:
            print("")
            processReceivedData(data)
        case "2AF1".CBUUIDRepresentation:
//            if let device = device as? OBDVehicleMetricsDevice {
//                device.ecuWriteCharacteristic = characteristic
//            }
            print("")
            processReceivedData(data)
        case "FFE1".CBUUIDRepresentation:
            processReceivedData(data)
//            if let device = device as? OBDVehicleMetricsDevice {
//                device.ecuWriteCharacteristic = characteristic
//            }
           
            print("")
        case "FFF1".CBUUIDRepresentation:
            print("")
        default:
            debugPrint("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
       // FFF2 ?
        
//        switch characteristic.uuid.uuidString {
//        case "FFE1": // for servcice FFE0
//            ecuWriteCharacteristic = characteristic
//            ecuReadCharacteristic = characteristic
//        case "FFF1": // for servcice FFF0
//            ecuReadCharacteristic = characteristic
//        case "FFF2": // for servcice FFF0
//            ecuWriteCharacteristic = characteristic
//        case "2AF0": // for servcice 18F0
//            ecuReadCharacteristic = characteristic
//        case "2AF1": // for servcice 18F0
//            ecuWriteCharacteristic = characteristic
//        default:
//            break
//        }
        
        
    }
    
    func processReceivedData(_ data: Data) {
        buffer.append(data)

        guard let string = String(data: buffer, encoding: .utf8) else {
            buffer.removeAll()
            return
        }

        if string.contains(">") {
            var lines = string
                .components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            // remove the last line
            lines.removeLast()
            #if DEBUG
                logger.debug("Response: \(lines)")
            #endif

            if BLEManager.shared.sendMessageCompletion != nil {
                if lines[0].uppercased().contains("NO DATA") {
                    BLEManager.shared.sendMessageCompletion?(nil, BLEManagerError.noData)
                } else {
                    BLEManager.shared.sendMessageCompletion?(lines, nil)
                }
            }
            buffer.removeAll()
        }
    }

}
