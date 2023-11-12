//
//  BLETemperatureSensor.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import CoreBluetooth

struct DeviceXX {
    
    static let SensorTagAdvertisingUUID = "AA10"
    
    static let TemperatureServiceUUID = "F000AA00-0451-4000-B000-000000000000"
    static let TemperatureDataUUID = "F000AA01-0451-4000-B000-000000000000"
    static let TemperatureConfig = "F000AA02-0451-4000-B000-000000000000"

    static let HumidityServiceUUID = "F000AA20-0451-4000-B000-000000000000"
    static let HumidityDataUUID = "F000AA21-0451-4000-B000-000000000000"
    static let HumidityConfig = "F000AA22-0451-4000-B000-000000000000"

    static let SensorDataIndexTempInfrared = 0
    static let SensorDataIndexTempAmbient = 1
    static let SensorDataIndexHumidityTemp = 0
    static let SensorDataIndexHumidity = 1
}

public enum Endian {
    case little
    case big
}

public extension Data {

    func extractNumber<N: Numeric>(fromOffset: Int) -> N {
        let range: ClosedRange<Index> = fromOffset...(fromOffset + MemoryLayout<N>.size)
        let subdata = subdata(in: range.lowerBound..<range.upperBound)

        return subdata.withUnsafeBytes { $0.load(as: N.self) }
    }

    func extractUInt8(fromOffset: Int) -> UInt8 {
        extractNumber(fromOffset: fromOffset)
    }

    func extractInt8(fromOffset: Int) -> Int8 {
        extractNumber(fromOffset: fromOffset)
    }

    func extractUInt16(fromOffset: Int, endian: Endian = .little) -> UInt16 {

        let value: UInt16 = extractNumber(fromOffset: fromOffset)

        return endian == .little ? value : value.bigEndian
    }

    func extractInt16(fromOffset: Int, endian: Endian = .little) -> Int16 {
        let value: Int16 = extractNumber(fromOffset: fromOffset)

        return endian == .little ? value : value.bigEndian
    }

    func extractUInt32(fromOffset: Int, endian: Endian = .little) -> UInt32 {
        let value: UInt32 = extractNumber(fromOffset: fromOffset)

        return endian == .little ? value : value.bigEndian
    }

    func extractInt32(fromOffset: Int, endian: Endian = .little) -> Int32 {
        let value: Int32 = extractNumber(fromOffset: fromOffset)

        return endian == .little ? value : value.bigEndian
    }

    func extractFloat(fromOffset: Int, endian: Endian = .little) -> Float {
        extractNumber(fromOffset: fromOffset)
    }
}

final class BLETemperatureSensor: Sensor {
    
    let kCharHWVer: String                = "2A27"
    let kCharFWVer: String                = "2A26"
    let kCharBatteryLevel: String         = "2A19"
    let kCharManufactor: String           = "2A29"
    let kCharModel: String                = "2A24"
    
    private var lastTemperatureData: TemperatureData?
    
    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        [.temperature]
    }
    
    override func getLastSensorDataList() -> [SensorData]? {
        if let lastTemperatureData {
            return [lastTemperatureData]
        }
        return nil
    }
    
    
     func displayTemperature(_ data:Data) {
         // We'll get four bytes of data back, so we divide the byte count by two
         // because we're creating an array that holds two 16-bit (two-byte) values
         let dataLength = data.count / MemoryLayout<UInt16>.size
         var dataArray = [UInt16](repeating: 0, count: dataLength)
         (data as NSData).getBytes(&dataArray, length: dataLength * MemoryLayout<Int16>.size)

 //        // output values for debugging/diagnostic purposes
 //        for i in 0 ..< dataLength {
 //            let nextInt:UInt16 = dataArray[i]
 //            print("next int: \(nextInt)")
 //        }
         
         let rawAmbientTemp:UInt16 = dataArray[DeviceXX.SensorDataIndexTempAmbient]
         let ambientTempC = Double(rawAmbientTemp) / 128.0
         let ambientTempF = convertCelciusToFahrenheit(ambientTempC)
         print("*** AMBIENT TEMPERATURE SENSOR (C/F): \(ambientTempC), \(ambientTempF)");
         
         // Device also retrieves an infrared temperature sensor value, which we don't use in this demo.
         // However, for instructional purposes, here's how to get at it to compare to the ambient temperature:
         let rawInfraredTemp:UInt16 = dataArray[DeviceXX.SensorDataIndexTempInfrared]
         let infraredTempC = Double(rawInfraredTemp) / 128.0
         let infraredTempF = convertCelciusToFahrenheit(infraredTempC)
         print("*** INFRARED TEMPERATURE SENSOR (C/F): \(infraredTempC), \(infraredTempF)");
         
         let temp = Int(ambientTempF)
         print("*** LAST TEMPERATURE CAPTURED: \(temp)° F")
         
     }
    
    func convertCelciusToFahrenheit(_ celcius: Double) -> Double {
        let fahrenheit = (celcius * 1.8) + Double(32)
        return fahrenheit
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        guard let data = characteristic.value  else {
            print("no data")
            return
        }
        
        let byteArray = [UInt8](data)
        
        if byteArray.count >= 5 && (byteArray[0] & 0x01) != 0 {
             // Извлекаем значение температуры
             let temperatureValue = Float(bitPattern: UInt32(byteArray[1]) | UInt32(byteArray[2]) << 8 | UInt32(byteArray[3]) << 16 | UInt32(byteArray[4]) << 24)
             
             print("Текущая температура 0: \(temperatureValue) градусов")
         }
        
        // Проверяем, что в массиве есть достаточно данных для измерения температуры
        if byteArray.count >= 5 && byteArray[0] & 0x01 != 0 {
            // Извлекаем значение температуры
            let temperatureValue = Float(Int16(byteArray[1]) | Int16(byteArray[2]) << 8) / 10.0
            
            // Используем значение температуры по своему усмотрению
            print("Текущая температура: \(temperatureValue) градусов")
            let temperature = Double((Int(byteArray[1]) & 0x7F) << 8 | Int(byteArray[0])) / 100
            print("temperature:\(temperature)")
            
            let temperature1 = Float(data.extractUInt16(fromOffset: 1)) / 10.0
            print("temperature1:\(temperature)")
        }
        
//        if let temperatureData = characteristic.value {
//            let temperatureValue = extractTemperature(from: temperatureData)
//            print("Текущая температура: \(temperatureValue) градусов")
//        } else {
//            print("Значение температуры недоступно")
//        }
//
//        func extractTemperature(from data: Data) -> Float {
//            let value = data.withUnsafeBytes { $0.load(as: UInt32.self) }
//            let scaledValue = Float(value) / 100.0
//            return scaledValue
//        }
        
        
       // displayTemperature(data)
        let uuidc  = characteristic.uuid.uuidString


          if let dataString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String {
              print("")
          }
        //let byteArray = [UInt8](data)

        
        print("characteristic:\(uuidc) Data:\(String(decoding: data, as: UTF8.self))")

        if uuidc == kCharBatteryLevel
        {
            let byteArray = [UInt8](data)
            print("Batery:\(uuidc) Data:\(String(decoding: data, as: UTF8.self))")
        }
        if uuidc == kCharFWVer
        {
            print("FW:\(uuidc) Data:\(String(decoding: data, as: UTF8.self))")
        }
        if uuidc == kCharHWVer
        {
            print("HW:\(uuidc) Data:\(String(decoding: data, as: UTF8.self))")
        }
        
        
        switch characteristic.uuid {
        case GattAttributes.CHAR_TEMPERATURE_MEASUREMENT.CBUUIDRepresentation:
            break
//            let heartRate = heartRate(from: characteristic)
//            if lastHeartRateData == nil {
//                lastHeartRateData = HeartRateData()
//            }
//            if let lastHeartRateData {
//                if lastHeartRateData.heartRate != heartRate {
//                    lastHeartRateData.heartRate = heartRate
//                    result(.success)
//                }
//                debugPrint("bpm: \(lastHeartRateData.heartRate)")
//            }
        default:
            debugPrint("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    public class TemperatureData: SensorData {
        
        let timestamp: Int64
        let temperature: Double
        
        init(timestamp: Int64, temperature: Double) {
            self.timestamp = timestamp
            self.temperature = temperature
        }
        
//        func getDataFields() -> [SensorDataField] {
//            return [SensorDataField(R.string.external_device_characteristic_temperature, R.string.degree_celsius, temperature)]
//        }
//        
//        func getExtraDataFields() -> [SensorDataField] {
//            return [SensorDataField(R.string.shared_string_time, -1, timestamp)]
//        }
//        
//        func getWidgetFields() -> [SensorWidgetDataField]? {
//            return [SensorWidgetDataField(SensorWidgetDataFieldType.TEMPERATURE, R.string.external_device_characteristic_temperature, -1, temperature)]
//        }
        
        func toString() -> String {
            return "BatteryData {timestamp=\(timestamp), temperature=\(temperature)}"
        }
    }
    
}

//public class BLETemperatureSensor: Sensor {
//    
//    private var lastTemperatureData: TemperatureData?
//    
//    public class TemperatureData: SensorData {
//        
//        let timestamp: Int64
//        let temperature: Double
//        
//        init(timestamp: Int64, temperature: Double) {
//            self.timestamp = timestamp
//            self.temperature = temperature
//        }
//        
//        func getTimestamp() -> Int64 {
//            return timestamp
//        }
//        
//        func getTemperature() -> Double {
//            return temperature
//        }
//        
//        func getDataFields() -> [SensorDataField] {
//            return [SensorDataField(R.string.external_device_characteristic_temperature, R.string.degree_celsius, temperature)]
//        }
//        
//        func getExtraDataFields() -> [SensorDataField] {
//            return [SensorDataField(R.string.shared_string_time, -1, timestamp)]
//        }
//        
//        func getWidgetFields() -> [SensorWidgetDataField]? {
//            return [SensorWidgetDataField(SensorWidgetDataFieldType.TEMPERATURE, R.string.external_device_characteristic_temperature, -1, temperature)]
//        }
//        
//        func toString() -> String {
//            return "BatteryData {timestamp=\(timestamp), temperature=\(temperature)}"
//        }
//    }
//    
//    public init(device: BLEAbstractDevice) {
//        super.init(device: device, sensorId: device.getDeviceId() + "_temperature")
//    }
//    
//    public init(device: BLEAbstractDevice, sensorId: String) {
//        super.init(device: device, sensorId: sensorId)
//    }
//    
//    override func getSupportedWidgetDataFieldTypes() -> [SensorWidgetDataFieldType] {
//        return [SensorWidgetDataFieldType.TEMPERATURE]
//    }
//    
//    override func getRequestedCharacteristicUUID() -> UUID {
//        return GattAttributes.UUID_CHAR_TEMPERATURE_UUID
//    }
//    
//    override func getName() -> String {
//        return "Temperature"
//    }
//    
//    override func getLastSensorDataList() -> [SensorData]? {
//        return [lastTemperatureData].compactMap { $0 }
//    }
//    
//    func getLastTemperatureData() -> TemperatureData? {
//        return lastTemperatureData
//    }
//    
//    override func onCharacteristicRead(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int) {
//        
//    }
//    
//    override func onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
//        let charaUUID = characteristic.uuid
//        if getRequestedCharacteristicUUID() == charaUUID {
//            decodeTemperatureCharacteristic(gatt: gatt, characteristic: characteristic)
//        }
//    }
//    
//    private func decodeTemperatureCharacteristic(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
//        let temperature: Double = characteristic.getFloatValue(format: BluetoothGattCharacteristic.FORMAT_FLOAT, offset: 1)
//        let data = TemperatureData(timestamp: Int64(Date().timeIntervalSince1970 * 1000), temperature: temperature)
//        self.lastTemperatureData = data
//        getDevice().fireSensorDataEvent(sensor: self, data: data)
//    }
//    
//    override func writeSensorDataToJson(json: JSONObject, widgetDataFieldType: SensorWidgetDataFieldType) throws {
//        guard let data = lastTemperatureData else { return }
//        json.put(SENSOR_TAG_TEMPERATURE, data.temperature)
//    }
//}
