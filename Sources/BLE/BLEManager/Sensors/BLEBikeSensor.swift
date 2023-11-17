//
//  BLEBikeSensor.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 24.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import CoreBluetooth

struct MeasurementFlags: OptionSet {
    let rawValue: UInt8
    
    static let WheelRevolutionDataPresent   = MeasurementFlags(rawValue: 1 << 0)
    static let CrankRevolutionDataPresent   = MeasurementFlags(rawValue: 1 << 1)
}

public extension SignedInteger {
    
    /// Increment this SignedInteger by 1
    mutating func increment() {
        self = self.advanced(by: 1)
    }
    
    /// Decrement this SignedInteger by 1
    mutating func decrement() {
        self = self.advanced(by: -1)
    }
}

prefix operator ++=
postfix operator ++=
prefix operator --=
postfix operator --=

/// Increment this SignedInteger and return the new value
public prefix func ++= <T: SignedInteger>(v: inout T) -> T {
    v.increment()
    return v
}

/// Increment this SignedInteger and return the old value
public postfix func ++= <T: SignedInteger>(v: inout T) -> T {
    let result = v
    v.increment()
    return result
}

/// Decrement this SignedInteger and return the new value
public prefix func --= <T: SignedInteger>(v: inout T) -> T {
    v.decrement()
    return v
}

/// Decrement this SignedInteger and return the old value
public postfix func --= <T: SignedInteger>(v: inout T) -> T {
    let result = v
    v.decrement()
    return result
}

final class BLEBikeSensor: Sensor {
    
    private(set) var firstWheelRevolutions: Float = 0
    private(set) var lastWheelRevolutions: Float = 0
    private(set) var lastWheelEventTime: Float = 0
    private(set) var wheelCadence: Float = 0
    private(set) var lastCrankRevolutions: Float = 0
    private(set) var lastCrankEventTime: Float = 0

    private(set) var wheelSize: Float = 2.086 //m

    private(set) var lastBikeCadenceData: BikeCadenceData = BikeCadenceData()
    private(set) var lastBikeSpeedDistanceData: BikeSpeedDistanceData = BikeSpeedDistanceData()
    
    final class BikeCadenceData: SensorData {
        var timestamp: Double = 0.0
        var gearRatio: Float = 0.0
        var cadence: Int = 0
    }
    
    final class BikeSpeedDistanceData: SensorData {
        var timestamp: Double = 0.0
        var speed: Float = 0.0
        var distance: Float = 0.0
        var totalDistance: Float = 0.0
    }
    
    private func decodeSpeed(from characteristic: CBCharacteristic) {
        guard let characteristicData = characteristic.value else { return }
        
        let bytes = characteristicData.map { $0 }
        var index: Int = 0
        
        let rawFlags: UInt8 = bytes[index++=]
        let flags = MeasurementFlags(rawValue: rawFlags)
        
        
       // let flag = characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT8, offset: 0)
        let wheelRevPresent: Bool = flags.contains(.WheelRevolutionDataPresent)
        let crankRevPresent: Bool = flags.contains(.CrankRevolutionDataPresent)
        var wheelRevolutions: Float
        var lastWheelEventTime: Float
        
//        public static final int FORMAT_SFLOAT = 50;
//           public static final int FORMAT_SINT16 = 34;
//           public static final int FORMAT_SINT32 = 36;
//           public static final int FORMAT_SINT8 = 33;
//           public static final int FORMAT_UINT16 = 18;
//           public static final int FORMAT_UINT32 = 20;
        
        if wheelRevPresent {
//            wheelRevolutions = characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT32, offset: 1)
//            lastWheelEventTime = characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT16, offset: 5)
            
            var cumulativeWheelRevolutions = UInt32(bytes[index++=])
            cumulativeWheelRevolutions |= UInt32(bytes[index++=]) << 8
            cumulativeWheelRevolutions |= UInt32(bytes[index++=]) << 16
            cumulativeWheelRevolutions |= UInt32(bytes[index++=]) << 24
            wheelRevolutions = Float(cumulativeWheelRevolutions)
            lastWheelEventTime = Float(UInt16(bytes[index++=]) | UInt16(bytes[index++=]) << 8)
            
            let circumference: Float = wheelSize
            
            if firstWheelRevolutions < 0 {
                firstWheelRevolutions = wheelRevolutions
            }
            
            if self.lastWheelEventTime == lastWheelEventTime {
                let totalDistance: Float = Float(wheelRevolutions) * circumference
                let distance: Float = Float(wheelRevolutions - firstWheelRevolutions) * circumference // m
                var speed: Float = lastBikeSpeedDistanceData.speed
                
//                if let lastBikeSpeedDistanceData = lastBikeSpeedDistanceData {
//                    speed = lastBikeSpeedDistanceData.speed
//                }
                
                lastBikeSpeedDistanceData.distance = distance
                lastBikeSpeedDistanceData.totalDistance = totalDistance
                lastBikeSpeedDistanceData.speed = speed
                lastBikeSpeedDistanceData.timestamp = Date.timeIntervalSinceReferenceDate
                
               //// getDevice().fireSensorDataEvent(self, createBikeSpeedDistanceData(speed, distance, totalDistance))
            } else if lastWheelRevolutions >= 0 {
                var timeDifference: Float
                
                if self.lastWheelEventTime < lastWheelEventTime {
                    timeDifference = (65535 + Float(lastWheelEventTime) - Float(self.lastWheelEventTime)) / 1024.0
                } else {
                    timeDifference = (Float(lastWheelEventTime) - Float(self.lastWheelEventTime)) / 1024.0
                }
                
                let distanceDifference: Float = Float(wheelRevolutions - lastWheelRevolutions) * circumference
                let totalDistance: Float = Float(wheelRevolutions) * circumference
                let distance: Float = Float(wheelRevolutions - firstWheelRevolutions) * circumference
                let speed: Float = distanceDifference / timeDifference
                
                wheelCadence = (Float(wheelRevolutions - lastWheelRevolutions) * 60.0) / timeDifference
                
                lastBikeSpeedDistanceData.distance = distance
                lastBikeSpeedDistanceData.totalDistance = totalDistance
                lastBikeSpeedDistanceData.speed = speed
                lastBikeSpeedDistanceData.timestamp = Date.timeIntervalSinceReferenceDate
            }
            
            lastWheelRevolutions = wheelRevolutions
            self.lastWheelEventTime = lastWheelEventTime
        } else if crankRevPresent {
//            let crankRevolutions = characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT16, offset: 1)
//            let lastCrankEventTime = characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT16, offset: 3)
            
            let crankRevolutions = UInt16(bytes[index++=]) | UInt16(bytes[index++=]) << 8
            let lastCrankEventTime = UInt16(bytes[index++=]) | UInt16(bytes[index++=]) << 8
            
            if lastCrankRevolutions >= 0 {
                var timeDifference: Float
                
                if self.lastCrankEventTime < Float(lastCrankEventTime) {
                    timeDifference = (65535 + Float(lastCrankEventTime) - Float(self.lastCrankEventTime)) / 1024.0
                } else {
                    timeDifference = (Float(lastCrankEventTime) - Float(self.lastCrankEventTime)) / 1024.0
                }
                
                let crankCadence: Float = (Float(crankRevolutions) - Float(lastCrankRevolutions)) * 60.0 / timeDifference
                
                if crankCadence > 0 {
                    let gearRatio: Float = wheelCadence / crankCadence
                    lastBikeCadenceData.cadence = Int(crankCadence.rounded())
                    lastBikeCadenceData.gearRatio = gearRatio
                }
            }
            
            lastCrankRevolutions = Float(crankRevolutions)
            self.lastCrankEventTime = Float(lastCrankEventTime)
        }
    }
    
//    private func decodeSpeed(from characteristic: CBCharacteristic) {
//        guard let characteristicData = characteristic.value else { return }
//        
//        let bytes = characteristicData.map { $0 }
//        var index: Int = 0
//        
//        let rawFlags: UInt8 = bytes[index++=]
//        let flags = MeasurementFlags(rawValue: rawFlags)
//        
//        let _wheelRevolutions: UInt32
//        let _lastWheelEventTime: UInt16
//        
//        if flags.contains(.WheelRevolutionDataPresent) {
//            var cumulativeWheelRevolutions = UInt32(bytes[index++=])
//            cumulativeWheelRevolutions |= UInt32(bytes[index++=]) << 8
//            cumulativeWheelRevolutions |= UInt32(bytes[index++=]) << 16
//            cumulativeWheelRevolutions |= UInt32(bytes[index++=]) << 24
//            _wheelRevolutions = cumulativeWheelRevolutions
//            _lastWheelEventTime = UInt16(bytes[index++=]) | UInt16(bytes[index++=]) << 8
//            
//            let circumference: Float = wheelSize
//            if firstWheelRevolutions == 0 {
//                firstWheelRevolutions = _wheelRevolutions
//            }
//            
//            if lastWheelEventTime == _lastWheelEventTime {
//                let totalDistance = Float(_wheelRevolutions) * circumference
//                let distance = Float(_wheelRevolutions - firstWheelRevolutions) * circumference; //m
//                lastBikeSpeedDistanceData?.distance = distance
//                lastBikeSpeedDistanceData?.totalDistance = totalDistance
//                lastBikeSpeedDistanceData?.timestamp = Date.timeIntervalSinceReferenceDate
//            } else if lastWheelRevolutions >= 0 {
//                let timeDifference: UInt16
//                if _lastWheelEventTime < lastWheelEventTime {
//                    timeDifference = (65535 + _lastWheelEventTime - lastWheelEventTime) / 1024
//                } else {
//                    timeDifference = (_lastWheelEventTime - lastWheelEventTime) / 1024
//                }
//                let distanceDifference = Float(_wheelRevolutions - lastWheelRevolutions) * circumference
//                let totalDistance = Float(_wheelRevolutions) * circumference
//                let distance =  Float(_wheelRevolutions - firstWheelRevolutions) * circumference
//                let speed = distanceDifference / Float(timeDifference)
//                wheelCadence = Float((_wheelRevolutions - lastWheelRevolutions) * 60) / Float(timeDifference)
//                
//                lastBikeSpeedDistanceData?.distance = distance
//                lastBikeSpeedDistanceData?.totalDistance = totalDistance
//                lastBikeSpeedDistanceData?.speed = speed
//                lastBikeSpeedDistanceData?.timestamp = Date.timeIntervalSinceReferenceDate
//            }
//            lastWheelRevolutions = _wheelRevolutions
//            lastWheelEventTime = _lastWheelEventTime
//        } else if flags.contains(.CrankRevolutionDataPresent) {
//            let _crankRevolutions = UInt16(bytes[index++=]) | UInt16(bytes[index++=]) << 8
//            let _lastCrankEventTime = UInt16(bytes[index++=]) | UInt16(bytes[index++=]) << 8
//            
//            if lastCrankRevolutions >= 0 {
//                var timeDifference: UInt16
//                if _lastCrankEventTime < lastCrankEventTime {
//                    timeDifference = (65535 + _lastCrankEventTime - lastCrankEventTime) / 1024
//                } else {
//                    timeDifference = (_lastCrankEventTime - lastCrankEventTime) / 1024
//                }
//                var crankCadence: Float = Float((_crankRevolutions - lastCrankRevolutions) * 60) / Float(timeDifference)
//                if crankCadence > 0 {
//                    let gearRatio = wheelCadence / crankCadence;
//                    lastBikeCadenceData?.cadence = Int(crankCadence.rounded())
//                    lastBikeCadenceData?.gearRatio = gearRatio
//                }
//            }
//            lastCrankRevolutions = _crankRevolutions;
//            lastCrankEventTime = _lastCrankEventTime;
//        }
//        timestamp = Date.timeIntervalSinceReferenceDate
//    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        switch characteristic.uuid {
        case GattAttributes.CHARACTERISTIC_CYCLING_SPEED_AND_CADENCE_MEASUREMENT.CBUUIDRepresentation:
            decodeSpeed(from: characteristic)
            result(.success)
        default:
            debugPrint("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}


//public class BLEBikeSensor extends BLEAbstractSensor
//
//
//
//    public BLEBikeSensor(@NonNull BLEAbstractDevice device) {
//        super(device, device.getDeviceId() + "_bike");
//    }
//
//    public BLEBikeSensor(@NonNull BLEAbstractDevice device, @NonNull String sensorId) {
//        super(device, sensorId);
//    }
//
//    @NonNull
//    @Override
//    public String getName() {
//        return "Bike Sensor";
//    }
//
//    @NonNull
//    @Override
//    public List<SensorWidgetDataFieldType> getSupportedWidgetDataFieldTypes() {
//        return Arrays.asList(
//                SensorWidgetDataFieldType.BIKE_SPEED,
//                SensorWidgetDataFieldType.BIKE_CADENCE,
//                SensorWidgetDataFieldType.BIKE_DISTANCE);
//    }
//
//    @Nullable
//    @Override
//    public List<SensorData> getLastSensorDataList() {
//        return Arrays.asList(lastBikeCadenceData, lastBikeSpeedDistanceData);
//    }
//
//    @NonNull
//    @Override
//    public UUID getRequestedCharacteristicUUID() {
//        return GattAttributes.UUID_CHARACTERISTIC_CYCLING_SPEED_AND_CADENCE_MEASUREMENT;
//    }
//
//    public void setWheelSize(float wheelSize) {
//        this.wheelSize = wheelSize;
//    }
//
//    @Override
//    public void onCharacteristicRead(@NonNull BluetoothGatt gatt,
//                                     @NonNull BluetoothGattCharacteristic characteristic,
//                                     int status) {
//    }
//
//    @Override
//    public void onCharacteristicChanged(@NonNull BluetoothGatt gatt,
//                                        @NonNull BluetoothGattCharacteristic characteristic) {
//        UUID charaUUID = characteristic.getUuid();
//        if (getRequestedCharacteristicUUID().equals(charaUUID)) {
//            decodeSpeedCharacteristic(gatt, characteristic);
//        }
//    }
//
//    private void decodeSpeedCharacteristic(@NonNull BluetoothGatt gatt,
//                                           @NonNull BluetoothGattCharacteristic characteristic) {
//        int flag = characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT8, 0);
//        boolean wheelRevPresent = (flag & 0x01) == 0x01;
//        boolean crankRevPreset = (flag & 0x02) == 0x02;
//        int wheelRevolutions;
//        int lastWheelEventTime;
//        if (wheelRevPresent) {
//            wheelRevolutions = characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT32, 1);
//            lastWheelEventTime = characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT16, 5);
//            float circumference = wheelSize;
//            if (firstWheelRevolutions < 0) {
//                firstWheelRevolutions = wheelRevolutions;
//            }
//            if (this.lastWheelEventTime == lastWheelEventTime) {
//                float totalDistance = (float) wheelRevolutions * circumference;
//                float distance = (float) (wheelRevolutions - firstWheelRevolutions) * circumference; //m
//                float speed = 0;
//                if (lastBikeSpeedDistanceData != null) {
//                    speed = lastBikeSpeedDistanceData.speed;
//                }
//                getDevice().fireSensorDataEvent(this, createBikeSpeedDistanceData(speed, distance, totalDistance));
//            } else if (lastWheelRevolutions >= 0) {
//                float timeDifference;
//                if (lastWheelEventTime < this.lastWheelEventTime) {
//                    timeDifference = (65535 + lastWheelEventTime - this.lastWheelEventTime) / 1024.0f;
//                } else {
//                    timeDifference = (lastWheelEventTime - this.lastWheelEventTime) / 1024.0f;
//                }
//                float distanceDifference = (wheelRevolutions - lastWheelRevolutions) * circumference;
//                float totalDistance = (float) wheelRevolutions * circumference;
//                float distance = (float) (wheelRevolutions - firstWheelRevolutions) * circumference;
//                float speed = (distanceDifference / timeDifference);
//                wheelCadence = (wheelRevolutions - lastWheelRevolutions) * 60.0f / timeDifference;
//                getDevice().fireSensorDataEvent(this, createBikeSpeedDistanceData(speed, distance, totalDistance));
//            }
//            lastWheelRevolutions = wheelRevolutions;
//            this.lastWheelEventTime = lastWheelEventTime;
//
//        } else if (crankRevPreset) {
//            int crankRevolutions = characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT16, 1);
//            int lastCrankEventTime = characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT16, 3);
//            if (lastCrankRevolutions >= 0) {
//                float timeDifference;
//                if (lastCrankEventTime < this.lastCrankEventTime) {
//                    timeDifference = (65535 + lastCrankEventTime - this.lastCrankEventTime) / 1024.0f;
//                } else {
//                    timeDifference = (lastCrankEventTime - this.lastCrankEventTime) / 1024.0f;
//                }
//                float crankCadence = (crankRevolutions - lastCrankRevolutions) * 60.0f / timeDifference;
//                if (crankCadence > 0) {
//                    float gearRatio = wheelCadence / crankCadence;
//                    getDevice().fireSensorDataEvent(this, createBikeCadenceData(gearRatio, Math.round(crankCadence)));
//                }
//            }
//            lastCrankRevolutions = crankRevolutions;
//            this.lastCrankEventTime = lastCrankEventTime;
//        }
//    }
//
//    //speed m/s, distance m
//    @NonNull
//    private SensorData createBikeSpeedDistanceData(float speed, float distance, float totalDistance) {
//        BikeSpeedDistanceData data = new BikeSpeedDistanceData(System.currentTimeMillis(), speed, distance, totalDistance);
//        lastBikeSpeedDistanceData = data;
//        return data;
//    }
//
//    @NonNull
//    private SensorData createBikeCadenceData(float gearRatio, int crankCadence) {
//        BikeCadenceData data = new BikeCadenceData(System.currentTimeMillis(), gearRatio, crankCadence);
//        lastBikeCadenceData = data;
//        return data;
//    }
//
//    @Override
//    public void writeSensorDataToJson(@NonNull JSONObject json, @NonNull SensorWidgetDataFieldType widgetDataFieldType) throws JSONException {
//        switch (widgetDataFieldType) {
//            case BIKE_SPEED:
//                if (lastBikeSpeedDistanceData != null) {
//                    json.put(SENSOR_TAG_SPEED, DECIMAL_FORMAT.format(lastBikeSpeedDistanceData.speed));
//                }
//                break;
//            case BIKE_CADENCE:
//                BikeCadenceData cadenceData = lastBikeCadenceData;
//                if (cadenceData != null) {
//                    json.put(SENSOR_TAG_CADENCE, cadenceData.cadence);
//                }
//                break;
//            case BIKE_DISTANCE:
//                if (lastBikeSpeedDistanceData != null) {
//                    json.put(SENSOR_TAG_DISTANCE, lastBikeSpeedDistanceData.distance);
//                }
//                break;
//            default:
//                break;
//        }
//    }
// }
