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
    
    private let visualizationMode = "visualization_mode"
    
    private(set) var externalDeviceId: String?
    
    private var cachedValue: String?
    private var deviceIdPref: OACommonString?
    private var visualizationModePref: OACommonInteger!
    private var appMode: OAApplicationMode!
    private var plugin: OAExternalSensorsPlugin?
    
    var shouldUseAnyConnectedDevice: Bool {
        deviceIdPref?.get(appMode) == plugin?.getAnyConnectedDeviceId()
    }
   
    convenience init(customId: String?, widgetType: WidgetType, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        self.init(frame: .zero)
        self.widgetType = widgetType
        self.appMode = appMode
        onClickFunction = { [weak self] _ in
            self?.changeNextMode()
        }
        plugin = OAPluginsHelper.getPlugin(OAExternalSensorsPlugin.self) as? OAExternalSensorsPlugin
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        deviceIdPref = registerSensorDevicePref(customId: customId)
        visualizationModePref = registerVisualizationModePref(customId: customId, widgetParams: widgetParams)
        
        if let id = widgetParams?[SensorTextWidget.externalDeviceIdConst] as? String {
            // For a newly created widget with selected device(not 1st)
            externalDeviceId = id
        } else {
            externalDeviceId = getDeviceId()
        }
        updateInfo()
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
                                  widgetConfigurationParams: [String: Any]?,
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
        
        let visualizationModeRow = section.createNewRow()
        visualizationModeRow.cellType = OAValueTableViewCell.getIdentifier()
        visualizationModeRow.iconTintColor = .iconColorDefault
        visualizationModeRow.title = localizedString("shared_string_show")
        visualizationModeRow.key = "value_pref"
        
        if let visualizationModePref {
            visualizationModeRow.setObj(visualizationModePref, forKey: "pref")
            if var currentValue = EOAExternalSensorVisualizationMode(rawValue: Int(visualizationModePref.defValue)) {
                if let widgetConfigurationParams,
                   let key = widgetConfigurationParams.keys.first(where: { $0.hasPrefix(visualizationMode) }),
                   let value = widgetConfigurationParams[key] as? String, let intValue = Int(value) {
                    if let sensorVisualizationMode = EOAExternalSensorVisualizationMode(rawValue: intValue) {
                        currentValue = sensorVisualizationMode
                    }
                } else {
                    if !isCreate {
                        guard let mode = EOAExternalSensorVisualizationMode(rawValue: Int(visualizationModePref.get(appMode))) else {
                            return nil
                        }
                        currentValue = mode
                    }
                }
                visualizationModeRow.setObj(getModeTitle(currentValue), forKey: "value")
                
                let outlinedIconName = if let plugin, let widgetType {
                    currentValue == .batteryLevel
                    ? plugin.batteryOutlinedIconName(for: widgetType)
                    : widgetType.disabledIconName
                } else {
                    "ic_custom_sensor"
                }
                visualizationModeRow.iconName = outlinedIconName
                section.footerText = if case .batteryLevel = currentValue {
                    localizedString("map_widget_battery") + ", " + localizedString("battery_level_settings_description")
                } else {
                    localizedString("sensor_data") + ", " + localizedString("sensor_data_settings_description")
                }
                
                visualizationModeRow.setObj(getPossibleValues(mode: currentValue), forKey: "possible_values")
            }
        }

        return data
    }
    
    private func changeNextMode() {
        guard let mode = getVisualizationMode() else {
            return
        }
        let nextMode: EOAExternalSensorVisualizationMode
        
        switch mode {
        case .sensorData:
            nextMode = .batteryLevel
        case .batteryLevel:
            nextMode = .sensorData
        @unknown default:
            return
        }
        
        visualizationModePref.set(Int32(nextMode.rawValue), mode: appMode)
        updateInfo()
    }
    
    private func getPossibleValues(mode: EOAExternalSensorVisualizationMode) -> [OATableRowData] {
        var rows = [OATableRowData]()
        
        guard let plugin, let widgetType else {
            return rows
        }

        for (index, titleKey) in ["sensor_data", "map_widget_battery"].enumerated() {
            let row = OATableRowData()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.setObj(index, forKey: "value")
            row.title = localizedString(titleKey)
            row.iconName = index == 0
                ? widgetType.disabledIconName
                : plugin.batteryOutlinedIconName(for: widgetType)
            
            row.iconTintColor = index == mode.rawValue ? .iconColorActive : .iconColorDisabled
            rows.append(row)
        }

        return rows
    }
    
    private func getModeTitle(_ mode: EOAExternalSensorVisualizationMode) -> String {
        switch mode {
        case .sensorData:
             localizedString("sensor_data")
        case .batteryLevel:
             localizedString("map_widget_battery")
        @unknown default:
            fatalError("getModeTitle unknown mode")
        }
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
        guard let widgetType,
              let mode = getVisualizationMode() else {
            setText("-", subtext: nil)
            return
        }
        
        var contentTitle = widgetType.title
        var iconName = widgetType.iconName
        
        switch mode {
        case .sensorData: break
        case .batteryLevel:
            contentTitle += ", " + localizedString("external_device_details_battery")
            if let plugin {
                iconName = plugin.batteryIconName(for: widgetType)
            }
        @unknown default: return
        }
        if !iconName.isEmpty {
            setIcon(iconName)
        }
        setContentTitle(contentTitle.uppercased())
        
        if let sensor {
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
        
        guard let mode = getVisualizationMode() else {
            return nil
        }
        
        if shouldUseAnyConnectedDevice {
            return getSensorFromConnectedDevice(for: widgetType, mode: mode)
        } else {
            return getSensorFromExternalDevice(for: widgetType, mode: mode)
        }
    }

    private func getVisualizationMode() -> EOAExternalSensorVisualizationMode? {
        guard let mode = EOAExternalSensorVisualizationMode(rawValue: Int(visualizationModePref.get(appMode))) else {
            return nil
        }
        return mode
    }

    private func getSensorFromConnectedDevice(for widgetType: WidgetType, mode: EOAExternalSensorVisualizationMode) -> Sensor? {
        if let device = DeviceHelper.shared.getConnectedDevicesForWidget(type: widgetType)?.first {
            return getSensorFromDevice(device, mode: mode, widgetType: widgetType)
        }
        return nil
    }

    private func getSensorFromExternalDevice(for widgetType: WidgetType, mode: EOAExternalSensorVisualizationMode) -> Sensor? {
        if let externalDeviceId, let device = getPairedDevicesForCurrentWidgetType().first(where: { $0.id == externalDeviceId }) {
            return getSensorFromDevice(device, mode: mode, widgetType: widgetType)
        }
        return nil
    }

    private func getSensorFromDevice(_ device: Device, mode: EOAExternalSensorVisualizationMode, widgetType: WidgetType) -> Sensor? {
        switch mode {
        case .sensorData:
            return device.sensors.compactMap { sensor in
                guard let supportedFieldTypes = sensor.getSupportedWidgetDataFieldTypes() else {
                    return nil
                }
                return supportedFieldTypes.contains(widgetType) ? sensor : nil
            }.first
        case .batteryLevel:
            return device.sensors.compactMap({ $0 as? BLEBatterySensor }).first
        @unknown default:
            return nil
        }
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
            if let externalDeviceId {
                saveDeviceId(deviceId: externalDeviceId)
            }
        }
    }

    private func registerSensorDevicePref(customId: String?) -> OACommonString? {
        if let plugin, let widgetId = customId ?? widgetType?.id, let fieldType = plugin.getWidgetDataFieldTypeName(byWidgetId: widgetId) {
            let prefId = fieldType + (customId ?? "")
            return OAAppSettings.sharedManager().registerStringPreference(prefId, defValue: plugin.getAnyConnectedDeviceId())
        }
        return nil
    }
    
    private func registerVisualizationModePref(customId: String?,
                                               widgetParams: ([String: Any])? = nil) -> OACommonInteger? {
        var prefId = visualizationMode
        if let customId, !customId.isEmpty {
            prefId += "\(customId)"
        }
        let preference = OAAppSettings.sharedManager().registerIntPreference(prefId, defValue: Int32(EOAExternalSensorVisualizationMode.sensorData.rawValue)).makeProfile()!
        if let string = widgetParams?[visualizationMode] as? String, let value = Int(string) {
            preference.set(Int32(value))
        }
        return preference
    }

    private func saveDeviceId(deviceId: String) {
        deviceIdPref?.setValueFrom(deviceId, appMode: appMode)
    }
}
