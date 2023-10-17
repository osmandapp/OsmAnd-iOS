//
//  Sensor.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 16.10.2023.
//

import CoreBluetooth

class Sensor {
    func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
    }
}

class SensorData {
    
}

//public static class BatteryData implements SensorData {
//
//    private final long timestamp;
//    private final int batteryLevel;
//
//    BatteryData(long timestamp, int batteryLevel) {
//        this.timestamp = timestamp;
//        this.batteryLevel = batteryLevel;
//    }
//
//    public long getTimestamp() {
//        return timestamp;
//    }
//
//    public int getBatteryLevel() {
//        return batteryLevel;
//    }
//
//    @NonNull
//    @Override
//    public List<SensorDataField> getDataFields() {
//        return Collections.singletonList(new SensorDataField(R.string.map_widget_battery, -1, batteryLevel));
//    }
//
//    @NonNull
//    @Override
//    public List<SensorDataField> getExtraDataFields() {
//        return Collections.singletonList(new SensorDataField(R.string.shared_string_time, -1, timestamp));
//    }
//
//    @Nullable
//    @Override
//    public List<SensorWidgetDataField> getWidgetFields() {
//        return Collections.singletonList(
//                new SensorWidgetDataField(SensorWidgetDataFieldType.BATTERY, R.string.map_widget_battery, -1, batteryLevel));
//    }
//
//    @NonNull
//    @Override
//    public String toString() {
//        return "BatteryData {" +
//                "timestamp=" + timestamp +
//                ", batteryLevel=" + batteryLevel +
//                '}';
//    }
//}


