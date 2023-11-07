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
    private(set) var externalDeviceId: String?
    
    convenience init(customId: String?, widgetType: WidgetType, widgetParams: ([String: Any])? = nil) {
        self.init(frame: .zero)
        setIcons(widgetType)
        self.widgetType = widgetType
        deviceIdPref = registerSensorDevicePref(customId: customId)
        externalDeviceId = getDeviceId(appMode: OAAppSettings.sharedManager().currentMode)
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
            if sensor.device.peripheral.state != .connected || dataList?.isEmpty ?? false {
                setText("-", subtext: nil)
                return
            }
            var field: SensorWidgetDataField?
            if let result = dataList?.first(where: { $0.getWidgetField(fieldType: widgetType) != nil }) {
                field = result.getWidgetField(fieldType: widgetType)
            }
            if let field, let formattedValue = field.getFormattedValue() {
                if cachedValue != formattedValue.value {
                    cachedValue = formattedValue.value
                    print("externalDeviceId: \(externalDeviceId) | value: \(formattedValue.value)")
                    setText(formattedValue.value, subtext: formattedValue.unit)
                }
            } else {
                setText("-", subtext: nil)
            }
        } else {
            setText("-", subtext: nil)
        }
    }
    
    override func updateInfo() -> Bool {
        if externalDeviceId == nil || externalDeviceId?.isEmpty ?? false {
            applyDeviceId()
        }
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
        if let externalDeviceId {
            if let device = DeviceHelper.shared.connectedDevices.first(where: { $0.id == externalDeviceId }) {
                let sensors = device.sensors.compactMap { $0.getSupportedWidgetDataFieldTypes() != nil ? $0 : nil }
                return sensors.first(where: { $0.getSupportedWidgetDataFieldTypes()!.contains(widgetType) })
            }
        }
        return nil
    }
    
    private func applyDeviceId() {
        if externalDeviceId == nil || externalDeviceId?.isEmpty ?? false {
            let connectedDevicesWithWidgetType = DeviceHelper.shared.connectedDevices.filter { $0.getSupportedWidgetDataFieldTypes()!.contains(widgetType!)}
            if connectedDevicesWithWidgetType.isEmpty {
                externalDeviceId = ""
            } else {
                if let widgetInfos = OAMapWidgetRegistry.sharedInstance().getAllWidgets(), !widgetInfos.isEmpty {
                    var visibleWidgetsIdsCurrentType = [String]()
                    for widgetInfo in widgetInfos where widgetInfo.widget.widgetType == widgetType {
                        if let sensorTextWidget = widgetInfo.widget as? Self {
                            if let externalDeviceId = sensorTextWidget.externalDeviceId, !externalDeviceId.isEmpty {
                                visibleWidgetsIdsCurrentType.append(externalDeviceId)
                            }
                        }
                    }
                    if visibleWidgetsIdsCurrentType.isEmpty {
                        externalDeviceId = connectedDevicesWithWidgetType.first?.id ?? ""
                    } else {
                        let devices = connectedDevicesWithWidgetType.filter { !visibleWidgetsIdsCurrentType.contains($0.id) }
                        if devices.isEmpty {
                            externalDeviceId = ""
                        } else {
                            externalDeviceId = devices.first?.id ?? ""
                        }
                    }
                } else {
                    externalDeviceId = connectedDevicesWithWidgetType.first?.id ?? ""
                }
            }
            saveDeviceId(deviceId: externalDeviceId!)
        }
    }
    
    func getDeviceId(appMode: OAApplicationMode) -> String? {
        deviceIdPref?.getProfileDefaultValue(appMode) as? String
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
    }
}
