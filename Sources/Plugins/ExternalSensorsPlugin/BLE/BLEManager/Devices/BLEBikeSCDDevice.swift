//
//  BLEBikeSCDDevice.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 24.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import CoreBluetooth

final class BLEBikeSCDDevice: Device {
    
    override var deviceServiceName: String {
        "Bike Sensor"
    }
    
    override class var getServiceUUID: String {
        GattAttributes.SERVICE_CYCLING_SPEED_AND_CADENCE
    }
    
    override var getServiceConnectedImage: UIImage? {
        getServiceImage(cadence: "widget_sensor_cadence",
                        speed: "widget_sensor_speed")
    }
    
    override var getServiceDisconnectedImage: UIImage? {
        getServiceImage(cadence: "ic_custom_sensor_cadence_outlined",
                        speed: "ic_custom_sensor_speed_outlined")
    }
    
    override var getDataFields: [[String: String]]? {
        if let sensor = sensors.first(where: { $0 is BLEBikeSensor }) as? BLEBikeSensor {
            var result = [[String: String]]()
            if let lastBikeSpeedDistanceData = sensor.lastBikeSpeedDistanceData {
                let speed = OAOsmAndFormatter.getFormattedSpeed(Float(lastBikeSpeedDistanceData.speed.value))
                let distance = OAOsmAndFormatter.getFormattedDistance(Float(lastBikeSpeedDistanceData.totalTravelDistance.value), with: OsmAndFormatterParams.noTrailingZeros)
                debugPrint("speed: \(speed ?? "")")
                debugPrint("distance: \(distance ?? "")")
                
                result.append([localizedString("external_device_characteristic_speed"): String(speed!)])
                result.append([localizedString("external_device_characteristic_total_distance"): String(distance!)])
            }
            if let lastBikeCadenceData = sensor.lastBikeCadenceData {
                result.append([localizedString("external_device_characteristic_cadence"): String(lastBikeCadenceData.cadence) + " " + localizedString("revolutions_per_minute_unit")])
            }
            return result.isEmpty ? nil : result
        }
        return nil
    }
    
    override var getSettingsFields: [String: Any]? {
        if let settings = DeviceHelper.shared.devicesSettingsCollection.getDeviceSettings(deviceId: id) {
            if let additionalParams = settings.additionalParams, let wheelCircumference = additionalParams[WheelDeviceSettings.WHEEL_CIRCUMFERENCE_KEY], let value = Float(wheelCircumference) {
                return [WheelDeviceSettings.WHEEL_CIRCUMFERENCE_KEY: value]
            } else {
                return [WheelDeviceSettings.WHEEL_CIRCUMFERENCE_KEY: Float(WheelDeviceSettings.DEFAULT_WHEEL_CIRCUMFERENCE)]
            }
        }
        return nil
    }
    
    init() {
        super.init(deviceType: .BLE_BICYCLE_SCD)
        sensors.append(BLEBikeSensor(device: self, sensorId: "bike_scd"))
    }
    
    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        [.bicycleSpeed, .bicycleCadence, .bicycleDistance]
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        sensors.forEach { $0.update(with: characteristic, result: result) }
    }
    
    override func configure() {
        guard let wheelCircumference = getWheelCircumference() else { return }
        setWheelCircumference(wheelCircumference: wheelCircumference)
    }
    
    func setWheelCircumference(wheelCircumference: Double) {
        guard let sensor = sensors.compactMap({ $0 as? BLEBikeSensor }).first else { return }
        sensor.wheelSize = wheelCircumference / 1000
    }
    
    private func getServiceImage(cadence: String, speed: String) -> UIImage? {
        if let sensor = sensors.first(where: { $0 is BLEBikeSensor }) as? BLEBikeSensor, sensor.lastBikeCadenceData != nil {
            return UIImage(named: cadence)
        }
        return UIImage(named: speed)
    }
    
    private func getWheelCircumference() -> Double? {
        guard let settings = DeviceHelper.shared.devicesSettingsCollection.getDeviceSettings(deviceId: id),
              let wheelCircumference = settings.additionalParams?[WheelDeviceSettings.WHEEL_CIRCUMFERENCE_KEY],
              let value = Double(wheelCircumference) else { return nil }
        return value
    }
}
