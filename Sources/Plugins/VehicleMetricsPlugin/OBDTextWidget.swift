//
//  OBDTextWidget.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 11.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class OBDTextWidget: OASimpleWidget {
    private static let measuredIntervalPrefKey = "average_obd_measured_interval_millis"
    private static let averageModePrefKey = "average_obd_mode"
    private static let defaultIntervalMillis: Int = 30 * 60 * 1000
    private static var availableIntervals: [Int: String] = getAvailableIntervals()
    
    private var cacheTextData: String?
    private var cacheSubTextData: String?
    private var measuredIntervalPref: OACommonLong?
    private var averageModePref: OACommonBoolean?
    private var fieldType: OBDDataComputer.OBDTypeWidget?
    
    var plugin: VehicleMetricsPlugin?
    var widgetComputer: OBDDataComputer.OBDComputerWidget?
    
    convenience init(customId: String?, widgetType: WidgetType, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        self.init(frame: .zero)
        self.fieldType = computeFieldType(for: widgetType)
        self.widgetType = widgetType
        self.plugin = OAPluginsHelper.getPlugin(VehicleMetricsPlugin.self) as? VehicleMetricsPlugin
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        var averageTimeSeconds = 0
        if supportsAverageMode() {
            measuredIntervalPref = registerMeasuredIntervalPref(customId, widgetParams: widgetParams, appMode: appMode)
            averageModePref = registerAverageModePref(customId, widgetParams: widgetParams, appMode: appMode)
            if averageModePref?.get() == true {
                averageTimeSeconds = (measuredIntervalPref?.get() ?? 0) / 1000
            }
        } else if fieldType == .fuelConsumptionRatePercentHour || fieldType == .fuelConsumptionRateLiterHour || fieldType == .fuelConsumptionRateLiterKm {
            averageTimeSeconds = Int(fieldType?.defaultAverageTime ?? 0)
        }
        
        if let fieldType {
            widgetComputer = OBDDataComputer.shared.registerWidget(type: fieldType, averageTimeSeconds: Int32(averageTimeSeconds))
        }
        
        updateInfo()
        setIconFor(widgetType)
        onClickFunction = { [weak self] _ in
            guard let self, self.supportsAverageMode(), let avgPref = self.averageModePref else { return }
            let newValue = !avgPref.get()
            avgPref.set(newValue)
            self.updatePrefs(prefsChanged: true)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult override func updateInfo() -> Bool {
        guard let widgetType, widgetType.isPurchased(), let plugin, let widgetComputer else { return false }
        let subtext = plugin.getWidgetUnit(widgetComputer.type)
        let textData = plugin.getWidgetValue(computerWidget: widgetComputer)
        if textData != cacheTextData || subtext != cacheSubTextData {
            setText(textData, subtext: subtext)
            cacheTextData = textData
            cacheSubTextData = subtext
        }
        
        updateWidgetName()
        configureShadowButtonMenu()
        return false
    }
    
    override func configureContextMenu(addGroup: UIMenu, settingsGroup: UIMenu, deleteGroup: UIMenu) -> UIMenu {
        var updatedSettingsGroup = settingsGroup
        if supportsAverageMode(), averageModePref?.get() == true {
            let resetAction = UIAction(title: localizedString("reset_average_value"), image: .icCustomReset) { [weak self] _ in
                guard let self else { return }
                self.resetAverageValue()
            }
            
            updatedSettingsGroup = settingsGroup.replacingChildren([resetAction] + settingsGroup.children)
        }
        
        return UIMenu(title: "", children: [addGroup, updatedSettingsGroup, deleteGroup])
    }
    
    override func getSettingsData(_ appMode: OAApplicationMode, widgetConfigurationParams: [String: Any]?, isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()
        if supportsAverageMode(), let averageModePref {
            let section = data.createNewSection()
            section.headerText = localizedString("shared_string_settings")
            
            let modeRow = section.createNewRow()
            modeRow.cellType = OAButtonTableViewCell.reuseIdentifier
            modeRow.key = "average_obd_mode_key"
            modeRow.title = localizedString("shared_string_mode")
            modeRow.setObj(averageModePref, forKey: "pref")
            let isAvg: Bool
            if isCreate, let widgetConfigurationParams, let override = widgetConfigurationParams[averageModePref.key] as? Bool {
                isAvg = override
            } else {
                isAvg = averageModePref.get()
            }
            let valueKeys = isTemperatureWidget() ? ["current_temperature", "average_temperature"] : ["shared_string_instant", "average"]
            let titleKey = valueKeys[isAvg ? 1 : 0]
            modeRow.setObj(localizedString(titleKey), forKey: "value")
            let possibleValues = valueKeys.enumerated().map { idx, key in
                let row = OATableRowData()
                row.cellType = OASimpleTableViewCell.reuseIdentifier
                row.setObj(idx, forKey: "value")
                row.title = localizedString(key)
                return row
            }
            modeRow.setObj(possibleValues, forKey: "possible_values")
            
            if isAvg, let measuredIntervalPref {
                let intervalRow = section.createNewRow()
                intervalRow.cellType = OAValueTableViewCell.reuseIdentifier
                intervalRow.key = "value_pref"
                intervalRow.title = localizedString("shared_string_interval")
                intervalRow.setObj(measuredIntervalPref, forKey: "pref")
                var currentValue = Self.defaultIntervalMillis
                if let widgetConfigurationParams, let key = widgetConfigurationParams.keys.first(where: { $0.hasPrefix(Self.measuredIntervalPrefKey) }), let str = widgetConfigurationParams[key] as? String, let v = Int(str) {
                    currentValue = v
                } else if !isCreate {
                    currentValue = Int(measuredIntervalPref.get(appMode))
                }
                intervalRow.setObj(OBDTextWidget.formatIntervals(interval: currentValue), forKey: "value")
                let sliderRow = OATableRowData()
                sliderRow.key = "values"
                sliderRow.cellType = OASegmentSliderTableViewCell.reuseIdentifier
                sliderRow.title = localizedString("shared_string_interval")
                sliderRow.setObj(Self.availableIntervals, forKey: "values")
                intervalRow.setObj([sliderRow], forKey: "possible_values")
            }
        }
        
        return data
    }
    
    override func isMetricSystemDepended() -> Bool {
        true
    }
    
    private func computeFieldType(for widgetType: WidgetType) -> OBDDataComputer.OBDTypeWidget {
        switch widgetType {
        case .OBDSpeed:
            return .speed
        case .OBDRpm:
            return .rpm
        case .OBDEngineRuntime:
            return .engineRuntime
        case .OBDFuelPressure:
            return .fuelPressure
        case .OBDAirIntakeTemp:
            return .temperatureIntake
        case .engineOilTemperature:
            return .engineOilTemperature
        case .OBDAmbientAirTemp:
            return .temperatureAmbient
        case .OBDBatteryVoltage:
            return .batteryVoltage
        case .OBDEngineCoolantTemp:
            return .temperatureCoolant
        case .OBDCalculatedEngineLoad:
            return .calculatedEngineLoad
        case .OBDThrottlePosition:
            return .throttlePosition
        default:
            return .speed
        }
    }
    
    private func updateWidgetName() {
        guard let widgetName = widgetType?.title, !widgetName.isEmpty else { return }
        let finalName: String
        if supportsAverageMode(), averageModePref?.get() == true {
            let ms: Int
            if let rawMs = measuredIntervalPref?.get() {
                ms = Int(rawMs)
            } else {
                ms = Self.defaultIntervalMillis
            }
            let formattedInterval = OBDTextWidget.formatIntervals(interval: ms)
            let format = localizedString("ltr_or_rtl_combine_via_colon")
            finalName = String(format: format, widgetName, formattedInterval).uppercased()
        } else {
            finalName = widgetName.uppercased()
        }
        
        setContentTitle(finalName)
        configureSimpleLayout()
    }
    
    private func registerAverageModePref(_ customId: String?, widgetParams: [String: Any]?, appMode: OAApplicationMode) -> OACommonBoolean {
        let prefId: String
        if let customId, !customId.isEmpty {
            prefId = Self.averageModePrefKey + customId
        } else {
            prefId = Self.averageModePrefKey
        }
        
        guard let preference = OAAppSettings.sharedManager().registerBooleanPreference(prefId, defValue: false).makeProfile() else { fatalError("Failed to register preference \(prefId)") }
        if let widgetParams {
            if let rawBool = widgetParams[prefId] as? Bool {
                preference.set(rawBool, mode: appMode)
            } else if let rawBase = widgetParams[Self.averageModePrefKey] as? Bool {
                preference.set(rawBase, mode: appMode)
            }
        }
        
        return preference
    }
    
    private func registerMeasuredIntervalPref(_ customId: String?, widgetParams: [String: Any]?, appMode: OAApplicationMode) -> OACommonLong {
        let prefId: String
        if let customId, !customId.isEmpty {
            prefId = Self.measuredIntervalPrefKey + customId
        } else {
            prefId = Self.measuredIntervalPrefKey
        }
        
        guard let preference = OAAppSettings.sharedManager().registerLongPreference(prefId, defValue: Self.defaultIntervalMillis)?.makeProfile() else { fatalError("Failed to register preference \(prefId)") }
        if let widgetParams {
            if let rawString = widgetParams[prefId] as? String, let rawValue = Int(rawString) {
                preference.set(rawValue, mode: appMode)
            } else if let rawString = widgetParams[Self.measuredIntervalPrefKey] as? String, let rawValue = Int(rawString) {
                preference.set(rawValue, mode: appMode)
            }
        }
        
        return preference
    }
    
    private func resetAverageValue() {
        widgetComputer?.resetLocations()
        setText("—", subtext: nil)
    }
    
    private func supportsAverageMode() -> Bool {
        guard let widgetType else { return false }
        let supportedTypes: Set<WidgetType> = [
            .OBDRpm,
            .OBDSpeed,
            .OBDCalculatedEngineLoad,
            .OBDFuelPressure,
            .OBDThrottlePosition,
            .OBDBatteryVoltage,
            .OBDAirIntakeTemp,
            .engineOilTemperature,
            .OBDAmbientAirTemp,
            .OBDEngineCoolantTemp
        ]
        
        return supportedTypes.contains(widgetType)
    }
    
    private func isTemperatureWidget() -> Bool {
        guard let widgetType else { return false }
        let supportedTypes: Set<WidgetType> = [
            .OBDAirIntakeTemp,
            .engineOilTemperature,
            .OBDAmbientAirTemp,
            .OBDEngineCoolantTemp
        ]
        
        return supportedTypes.contains(widgetType)
    }
    
    func updatePrefs(prefsChanged: Bool) {
        guard supportsAverageMode() else { return }
        let newTimeSeconds: Int = {
            if averageModePref?.get() == true {
                return Int((measuredIntervalPref?.get() ?? 0) / 1000)
            } else {
                return 0
            }
        }()
        
        if prefsChanged {
            if let wc = widgetComputer {
                widgetComputer = OBDDataComputer.shared.registerWidget(type: wc.type, averageTimeSeconds: Int32(newTimeSeconds))
            }
        } else {
            widgetComputer?.averageTimeSeconds = Int32(newTimeSeconds)
        }
        
        self.updateInfo()
        configureShadowButtonMenu()
    }
    
    func getWidgetOBDCommand() -> OBDCommand? {
        fieldType?.requiredCommand
    }
}

extension OBDTextWidget {
    private static func getAvailableIntervals() -> [Int: String] {
        var intervals = [Int: String]()
        for intervalNum in OAAverageSpeedComputer.measured_INTERVALS() {
            let interval = intervalNum.intValue
            let seconds = interval < 60 * 1000
            let timeInterval = seconds ? String(interval / 1000) : String(interval / 1000 / 60)
            let timeUnit = interval < 60 * 1000 ? localizedString("shared_string_sec") : localizedString("int_min")
            let formattedInterval = String(format: localizedString("ltr_or_rtl_combine_via_space"), arguments: [timeInterval, timeUnit])
            intervals[interval] = formattedInterval
        }

        return intervals
    }

    static func formatIntervals(interval: Int) -> String {
        let isSeconds = interval < 60 * 1000
        let count = isSeconds ? interval / 1000 : interval / (60 * 1000)
        let timeInterval = "\(count)"
        let timeUnitKey = isSeconds ? "shared_string_sec" : "shared_string_minute_lowercase"
        let timeUnit = localizedString(timeUnitKey)
        let format = localizedString("ltr_or_rtl_combine_via_space")
        return String(format: format, timeInterval, timeUnit)
    }
}
