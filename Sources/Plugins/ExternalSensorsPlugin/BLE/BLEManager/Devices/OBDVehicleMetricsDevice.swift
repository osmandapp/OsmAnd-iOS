//
//  OBDVehicleMetricsDevice.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 14.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class OBDVehicleMetricsDevice: Device {
    override var deviceServiceName: String {
        "OBD Sensor"
    }
    
    class var getServicesUUID: [String] {
        ["FFE0", "FFF0", "18F0"]
    }
    
    override var getServiceConnectedImage: UIImage? {
        .widgetObdCar
    }
    
    override var getServiceDisconnectedImage: UIImage? {
        .icCustomCarObd2
    }
    
    init() {
        super.init(deviceType: .OBD_VEHICLE_METRICS)
        sensors.append(OBDVehicleMetricsSensor(device: self, sensorId: "vehicle_sensor"))
    }
    
//    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
//        [.bicycleSpeed, .bicycleCadence, .bicycleDistance]
//    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        sensors.forEach { $0.update(with: characteristic, result: result) }
    }
}
