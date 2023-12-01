//
//  BLERunningSensor.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 01.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class BLERunningSensor: Sensor {
    private var running = false

    private var lastRunningCadenceData: RunningCadenceData?
    private var lastRunningSpeedData: RunningSpeedData?
    private var lastRunningDistanceData: RunningDistanceData?
    private var lastRunningStrideLengthData: RunningStrideLengthData?

    class RunningCadenceData: SensorData {
        let timestamp: TimeInterval
        let cadence: Int
        
        init(timestamp: TimeInterval, cadence: Int) {
            self.timestamp = timestamp
            self.cadence = cadence
        }
        
        var widgetFields: [SensorWidgetDataField]? {
            [SensorWidgetDataField(fieldType: .bicycleCadence,
                                   nameId: localizedString("external_device_characteristic_cadence"),
                                   unitNameId: "",
                                   numberValue: nil,
                                   stringValue: String(cadence))]
        }
        
        var description: String {
            "RunningCadenceData { timestamp=\(timestamp), cadence=\(cadence) }"
        }
        
        func getWidgetField(fieldType: WidgetType) -> SensorWidgetDataField? {
            widgetFields?.first
        }
    }

    class RunningSpeedData: SensorData {
        let timestamp: Int64
        let speed: Float
        
        init(timestamp: Int64, speed: Float) {
            self.timestamp = timestamp
            self.speed = speed
        }
        
//        func getTimestamp() -> Int64 {
//            return timestamp
//        }
//        
//        func getSpeed() -> Float {
//            return speed
//        }
//        
//        func getDataFields() -> [SensorDataField] {
//            return [
//                SensorSpeedWidgetDataField(id: R.string.external_device_characteristic_speed, value: speed)
//            ]
//        }
//        
//        func getExtraDataFields() -> [SensorDataField] {
//            return [
//                SensorDataField(id: R.string.shared_string_time, value: timestamp)
//            ]
//        }
//        
//        func getWidgetFields() -> [SensorWidgetDataField]? {
//            return [
//                SensorSpeedWidgetDataField(id: R.string.external_device_characteristic_speed, value: speed)
//            ]
//        }
//        
//        func toString() -> String {
//            return "CadenceData { timestamp=\(timestamp), speed=\(speed) }"
//        }
    }

    class RunningDistanceData: SensorData {
        let timestamp: Int64
        let totalDistance: Float
        
        init(timestamp: Int64, totalDistance: Float) {
            self.timestamp = timestamp
            self.totalDistance = totalDistance
        }
        
        func getTimestamp() -> Int64 {
            return timestamp
        }
        
        func getTotalDistance() -> Float {
            return totalDistance
        }
        
        func getDataFields() -> [SensorDataField] {
            return [
                SensorDistanceWidgetDataField(id: R.string.external_device_characteristic_total_distance, value: totalDistance)
            ]
        }
        
        func getExtraDataFields() -> [SensorDataField] {
            return [
                SensorDataField(id: R.string.shared_string_time, value: timestamp)
            ]
        }
        
        func getWidgetFields() -> [SensorWidgetDataField]? {
            return [
                SensorDistanceWidgetDataField(id: R.string.external_device_characteristic_total_distance, value: totalDistance)
            ]
        }
        
        func toString() -> String {
            return "CadenceData { timestamp=\(timestamp), totalDistance=\(totalDistance) }"
        }
    }

    class RunningStrideLengthData: SensorData {
        let timestamp: Int64
        let strideLength: Float
        
        init(timestamp: Int64, strideLength: Float) {
            self.timestamp = timestamp
            self.strideLength = strideLength
        }
        
        func getTimestamp() -> Int64 {
            return timestamp
        }
        
        func getStrideLength() -> Float {
            return strideLength
        }
        
        func getDataFields() -> [SensorDataField] {
            return [
                SensorDistanceWidgetDataField(id: R.string.external_device_characteristic_stride_length, value: strideLength)
            ]
        }
        
        func getExtraDataFields() -> [SensorDataField] {
            return [
                SensorDataField(id: R.string.shared_string_time, value: timestamp)
            ]
        }
        
        func getWidgetFields() -> [SensorWidgetDataField]? {
            return [
                SensorDistanceWidgetDataField(id: R.string.external_device_characteristic_stride_length, value: strideLength)
            ]
        }
        
        func toString() -> String {
            return "CadenceData { timestamp=\(timestamp), strideLength=\(strideLength) }"
        }
    }

    class BLERunningSensor: BLEAbstractSensor {
        
        override init(device: BLEAbstractDevice) {
            super.init(device: device, sensorId: device.getDeviceId() + "_running")
        }
        
        override init(device: BLEAbstractDevice, sensorId: String) {
            super.init(device: device, sensorId: sensorId)
        }
        
        override func getName() -> String {
            return "Running Sensor"
        }
        
        override func getSupportedWidgetDataFieldTypes() -> [SensorWidgetDataFieldType] {
            return [
                .bikeSpeed,
                .bikeCadence,
                .bikeDistance
            ]
        }
        
        override func getLastSensorDataList() -> [SensorData]? {
            return [
                lastRunningCadenceData,
                lastRunningSpeedData,
                lastRunningDistanceData,
                lastRunningStrideLengthData
            ]
        }
        
        override func getRequestedCharacteristicUUID() -> UUID {
            return GattAttributes.UUID_CHARACTERISTIC_RUNNING_SPEED_AND_CADENCE_MEASUREMENT
        }
        
        override func onCharacteristicRead(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int) {
            // Implementation for onCharacteristicRead()
        }
        
        override func onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            let charaUUID = characteristic.uuid
            if getRequestedCharacteristicUUID() == charaUUID {
                decodeRunningSpeedCharacteristic(gatt: gatt, characteristic: characteristic)
            }
        }
        
        func isRunning() -> Bool {
            return running
        }
        
        private func decodeRunningSpeedCharacteristic(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            let flags = characteristic.value?[0] ?? 0
            
            let strideLengthPresent = flags & 0x01 != 0
            let totalDistancePreset = flags & 0x02 != 0
            running = flags & 0x04 != 0
            
            let speed = Float(characteristic.getIntValue(format: BluetoothGattCharacteristic.FORMAT_UINT16, offset: 1)) / 3.6 * 256.0
            let cadence = characteristic.getIntValue(format: BluetoothGattCharacteristic.FORMAT_UINT8, offset: 3)
            getDevice().fireSensorDataEvent(sensor: self, createRunningSpeedData(speed: speed))
            getDevice().fireSensorDataEvent(sensor: self, createRunningCadenceData(cadence: cadence))
            
            var strideLength: Float = -1
            if strideLengthPresent {
                strideLength = Float(characteristic.getIntValue(format: BluetoothGattCharacteristic.FORMAT_UINT16, offset: 4))
                getDevice().fireSensorDataEvent(sensor: self, createRunningStrideLengthData(strideLength: strideLength))
            }
            
            var totalDistance: Float = -1
            if totalDistancePreset {
                totalDistance = Float(characteristic.getIntValue(format: BluetoothGattCharacteristic.FORMAT_UINT32, offset: strideLengthPresent ? 6 : 4)) * 3.6 / 10.0
                getDevice().fireSensorDataEvent(sensor: self, createRunningDistanceData(totalDistance: totalDistance))
            }
        }
        
        private func createRunningSpeedData(speed: Float) -> SensorData {
            let data = RunningSpeedData(timestamp: Date().timeIntervalSince1970, speed: speed)
            lastRunningSpeedData = data
            return data
        }
        
        private func createRunningCadenceData(cadence: Int) -> SensorData {
            let data = RunningCadenceData(timestamp: Date().timeIntervalSince1970, cadence: cadence)
            lastRunningCadenceData = data
            return data
        }
        
        private func createRunningDistanceData(totalDistance: Float) -> SensorData {
            let data = RunningDistanceData(timestamp: Date().timeIntervalSince1970, totalDistance: totalDistance)
            lastRunningDistanceData = data
            return data
        }
        
        private func createRunningStrideLengthData(strideLength: Float) -> SensorData {
            let data = RunningStrideLengthData(timestamp: Date().timeIntervalSince1970, strideLength: strideLength)
            lastRunningStrideLengthData = data
            return data
        }

    
}
