//
//  SensorTextWidget.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 02.11.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import CoreBluetooth

@objcMembers
final class SensorTextWidget: OATextInfoWidget {
    private var cachedValue: String?
    private var deviceIdPref: OACommonPreference?
    private var externalDeviceId: String?
    
    convenience init(customId: String?, widgetType: WidgetType) {
        self.init(frame: .zero)
        setIcons(widgetType)
        self.widgetType = widgetType
        deviceIdPref = registerSensorDevicePref(customId: customId)
        externalDeviceId = getDeviceId(appMode: OAAppSettings.sharedManager().currentMode)
        applyDeviceId()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateSensorData(sensor: Sensor?) {
        if let sensor, let widgetType {
            let dataList = sensor.getLastSensorDataList()
            if sensor.device.peripheral?.state != .connected || dataList?.isEmpty ?? false {
                setText("-", subtext: nil)
                return
            }
            var field: SensorWidgetDataField?
            if let dataList {
                for data in dataList {
                    field = data.getWidgetField(fieldType: widgetType)
                    if field != nil {
                        break
                    }
                }
            }
            if let field {
                if let formattedValue = field.getFormattedValue() {
                    if cachedValue != formattedValue.value {
                        cachedValue = formattedValue.value
                        setText(formattedValue.value, subtext: formattedValue.unit)
                    }
                } else {
                    setText("-", subtext: nil)
                }
            } else {
                setText("-", subtext: nil)
            }
        } else {
            setText("-", subtext: nil)
        }
    }
    
    override func updateInfo() -> Bool {
        updateSensorData(sensor: getCurrentSensor())
        return false
    }
    
    override func isMetricSystemDepended() -> Bool {
        return true
    }
    
    private func getCurrentSensor() -> Sensor? {
        guard let widgetType else {
            return nil
        }
        for device in DeviceHelper.shared.connectedDevices {
            let sensors = device.sensors.compactMap { $0.getSupportedWidgetDataFieldTypes() != nil ? $0 : nil }
            return sensors.first(where: { $0.getSupportedWidgetDataFieldTypes()!.contains(widgetType) })
        }
        return nil
    }
    
    private func applyDeviceId() {
        var device: Device?
        if externalDeviceId == nil {
            var deviceList = [Device]()
            if let result = DeviceHelper.shared.connectedDevices.first(where: { $0.getSupportedWidgetDataFieldTypes()!.contains(widgetType!) }) {
                deviceList.append(result)
            }
            if deviceList.isEmpty {
                externalDeviceId = ""
            } else {
                device = deviceList.first
                externalDeviceId = device?.id ?? ""
            }
            saveDeviceId(deviceId: externalDeviceId!)
        }
    }
    
    private func getSensor(device: Device?) -> Sensor? {
        if let device {
            for sensor in device.sensors {
                if let types = sensor.getSupportedWidgetDataFieldTypes() {
                    if types.contains(widgetType!) {
                        return sensor
                    }
                }
            }
        }
        return nil
    }
    
    func getDeviceId(appMode: OAApplicationMode) -> String? {
        deviceIdPref?.getProfileDefaultValue(appMode) as? String
    }
    
    func setDeviceId(deviceId: String) {
        saveDeviceId(deviceId: deviceId)
        applyDeviceId()
    }
    
    func getFieldType() -> WidgetType {
        return widgetType!
    }
    
    private func registerSensorDevicePref(customId: String?) -> OACommonPreference {
        var prefId = widgetType!.title
        if let customId, !customId.isEmpty {
            prefId += customId
        }
        return OAAppSettings.sharedManager().registerStringPreference(prefId, defValue: nil).makeProfile() as! OACommonPreference
    }
    
    private func saveDeviceId(deviceId: String) {
        let appMode = OAAppSettings.sharedManager().applicationMode.get()
        deviceIdPref?.setValueFrom(deviceId, appMode: appMode)
        externalDeviceId = deviceId
    }
}
