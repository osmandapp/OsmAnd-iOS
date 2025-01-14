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
final class SensorTextWidget: OASimpleWidget {
    static let externalDeviceIdConst = "externalDeviceIdConst"
    
    private(set) var externalDeviceId: String?
    
    private var cachedValue: String?
    private var deviceIdPref: OACommonString?
    private var appMode: OAApplicationMode!
    private var plugin: OAExternalSensorsPlugin?
    
    var shouldUseAnyConnectedDevice: Bool {
        deviceIdPref?.get(appMode) == plugin?.getAnyConnectedDeviceId()
    }
   
    convenience init(customId: String?, widgetType: WidgetType, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        self.init(frame: .zero)
        setIconFor(widgetType)
        self.widgetType = widgetType
        self.appMode = appMode
        plugin = OAPluginsHelper.getPlugin(OAExternalSensorsPlugin.self) as? OAExternalSensorsPlugin
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        deviceIdPref = registerSensorDevicePref(customId: customId)
        
        if let id = widgetParams?[SensorTextWidget.externalDeviceIdConst] as? String {
            // For a newly created widget with selected device(not 1st)
            externalDeviceId = id
        } else {
            externalDeviceId = getDeviceId()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateInfo() -> Bool {
        if externalDeviceId == nil || externalDeviceId?.isEmpty ?? false {
            applyDeviceId()
        }
        updateSensorData(sensor: getCurrentSensor())
        return false
    }
    
    override func isMetricSystemDepended() -> Bool {
        true
    }
    
    override func getSettingsData(_ appMode: OAApplicationMode,
                                  widgetConfigurationParams: [String : Any]?,
                                  isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")

        let settingRow = section.createNewRow()
        settingRow.cellType = OAValueTableViewCell.getIdentifier()
        settingRow.iconName = "ic_custom_sensor"
        settingRow.iconTintColor = .iconColorDefault
        settingRow.key = "external_sensor_key"
        settingRow.title = localizedString("external_sensors_source_of_data")
        
        if externalDeviceId == nil || externalDeviceId?.isEmpty ?? false {
            applyDeviceId()
        }
        if let sensor = getCurrentSensor() {
            if shouldUseAnyConnectedDevice {
                settingRow.descr = localizedString("external_device_any_connected") + ": " + sensor.device.deviceName
            } else {
                settingRow.descr = sensor.device.deviceName
            }
        } else {
            settingRow.descr = localizedString(shouldUseAnyConnectedDevice ? "external_device_any_connected" : "shared_string_none")
        }

        return data
    }

    func getFieldType() -> WidgetType {
        widgetType!
    }
    
    func configureDevice(id: String) {
        externalDeviceId = id
        saveDeviceId(deviceId: id)
    }
    
    func setAnyDevice(use: Bool) {
        if use, let plugin {
            deviceIdPref?.set(plugin.getAnyConnectedDeviceId(), mode: appMode)
        }
    }
    
    private func updateSensorData(sensor: Sensor?) {
        if let sensor, let widgetType {
            let dataList = sensor.getLastSensorDataList(for: widgetType)
            if !sensor.device.isConnected || dataList?.isEmpty ?? false {
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
                    print("externalDeviceId: \(String(describing: externalDeviceId)) | value: \(formattedValue.value)")
                    if formattedValue.value != "0" {
                        setText(formattedValue.value, subtext: formattedValue.unit)
                    } else {
                        setText("-", subtext: nil)
                    }
                }
            } else {
                setText("-", subtext: nil)
            }
        } else {
            setText("-", subtext: nil)
        }
    }
    
    private func getDeviceId() -> String? {
        deviceIdPref?.getProfileDefaultValue(appMode) as? String
    }
    
    private func getCurrentSensor() -> Sensor? {
        guard let widgetType else {
            return nil
        }
        if shouldUseAnyConnectedDevice {
            if let device = DeviceHelper.shared.getConnectedDevicesForWidget(type: widgetType)?.first {
                return device.sensors.compactMap { $0.getSupportedWidgetDataFieldTypes() != nil ? $0 : nil }
                    .first(where: { $0.getSupportedWidgetDataFieldTypes()!.contains(widgetType) })
            }
        } else {
            if let externalDeviceId {
                if let device = getPairedDevicesForCurrentWidgetType().first(where: { $0.id == externalDeviceId }) {
                    return device.sensors.compactMap { $0.getSupportedWidgetDataFieldTypes() != nil ? $0 : nil }
                        .first(where: { $0.getSupportedWidgetDataFieldTypes()!.contains(widgetType) })
                }
            }
        }
        return nil
    }
    
    private func getPairedDevicesForCurrentWidgetType() -> [Device] {
        DeviceHelper.shared.getPairedDevicesFor(type: widgetType!) ?? []
    }
    
    private func applyDeviceId() {
        guard !shouldUseAnyConnectedDevice else {
            return
        }
        if externalDeviceId == nil || externalDeviceId?.isEmpty ?? false {
            let pairedDevicesWithWidgetType = getPairedDevicesForCurrentWidgetType()
            if pairedDevicesWithWidgetType.isEmpty {
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
                        externalDeviceId = pairedDevicesWithWidgetType.first?.id ?? ""
                    } else {
                        let devices = pairedDevicesWithWidgetType.filter { !visibleWidgetsIdsCurrentType.contains($0.id) }
                        if devices.isEmpty {
                            externalDeviceId = ""
                        } else {
                            externalDeviceId = devices.first?.id ?? ""
                        }
                    }
                } else {
                    externalDeviceId = pairedDevicesWithWidgetType.first?.id ?? ""
                }
            }
            saveDeviceId(deviceId: externalDeviceId!)
        }
    }

    private func registerSensorDevicePref(customId: String?) -> OACommonString? {
        if let plugin, let widgetId = customId ?? widgetType?.id, let fieldType = plugin.getWidgetDataFieldTypeName(byWidgetId: widgetId) {
            let prefId = fieldType + (customId ?? "")
            return OAAppSettings.sharedManager().registerStringPreference(prefId, defValue: plugin.getAnyConnectedDeviceId())
        }
        return nil
    }

    private func saveDeviceId(deviceId: String) {
        deviceIdPref?.setValueFrom(deviceId, appMode: appMode)
    }
}
