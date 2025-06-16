//
//  OBDTextWidget.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 11.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class OBDTextWidget: OASimpleWidget {
    private static let measuredIntervalPrefKey = "average_obd_measured_interval_millis"
    private static let averageModePrefKey = "average_obd_mode"
    private static let defaultIntervalMillis: Int = 30 * 60 * 1000
    
    private var plugin: VehicleMetricsPlugin?
    private var widgetComputer: OBDDataComputer.OBDComputerWidget?
    private var cacheTextData: String?
    private var cacheSubTextData: String?
    private var measuredIntervalPref: OACommonLong?
    private var averageModePref: OACommonBoolean?
    private var fieldType: OBDDataComputer.OBDTypeWidget?
    
    convenience init(customId: String?, widgetType: WidgetType, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        self.init(frame: .zero)
        self.fieldType = computeFieldType(for: widgetType)
        self.widgetType = widgetType
        self.plugin = OAPluginsHelper.getPlugin(VehicleMetricsPlugin.self) as? VehicleMetricsPlugin
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        var averageTimeSeconds = 0
        if supportsAverageMode() {
            measuredIntervalPref = registerMeasuredIntervalPref(customId)
            averageModePref = registerAverageModePref(customId)
            if averageModePref?.get() == true {
                averageTimeSeconds = (measuredIntervalPref?.get() ?? 0) / 1000
            }
        } else if fieldType == .fuelConsumptionRatePercentHour || fieldType == .fuelConsumptionRateLiterHour || fieldType == .fuelConsumptionRateLiterKm {
            averageTimeSeconds = Int(fieldType?.defaultAverageTime ?? 0)
        }
        
        if let fieldType {
            widgetComputer = OBDDataComputer.shared.registerWidget(type: fieldType, averageTimeSeconds: Int32(averageTimeSeconds))
        }
        
        _ = updateInfo()
        setIconFor(widgetType)
        onClickFunction = { [weak self] _ in
            guard let self, self.supportsAverageMode(), let avgPref = self.averageModePref else { return }
            let newValue = !avgPref.get()
            avgPref.set(newValue)
            self.updatePrefs(prefsChanged: true)
            _ = self.updateInfo()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateInfo() -> Bool {
        guard let wt = widgetType, wt.isPurchased(), let plug = plugin, let ft = fieldType, let comp = widgetComputer else { return false }
        let subtext = plug.getWidgetUnit(ft)
        let textData = plug.getWidgetValue(computerWidget: comp)
        if textData != cacheTextData || subtext != cacheSubTextData {
            setText(textData, subtext: subtext)
            cacheTextData = textData
            cacheSubTextData = subtext
        }
        
        updateWidgetName()
        return false
    }
    
    override func configureContextMenu(addGroup: UIMenu, settingsGroup: UIMenu, deleteGroup: UIMenu) -> UIMenu {
        let updatedSettingsGroup: UIMenu = {
            guard supportsAverageMode(), averageModePref?.get() == true else { return settingsGroup }
            let resetAction = UIAction(title: localizedString("reset_average_value"), image: .icCustomReset) { [weak self] _ in
                guard let self else { return }
                self.resetAverageValue()
            }
            
            return settingsGroup.replacingChildren([resetAction] + settingsGroup.children)
        }()
        
        return UIMenu(title: "", children: [addGroup, updatedSettingsGroup, deleteGroup])
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
        case .OBDRemainingFuel:
            return .fuelLeftLiter
        case .OBDCalculatedEngineLoad:
            return .calculatedEngineLoad
        case .OBDThrottlePosition:
            return .throttlePosition
        case .OBDFuelConsumption:
            return .fuelConsumptionRateLiterHour
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
    }
    
    private func registerAverageModePref(_ customId: String?) -> OACommonBoolean {
        let prefId: String
        if let id = customId, !id.isEmpty {
            prefId = Self.averageModePrefKey + id
        } else {
            prefId = Self.averageModePrefKey
        }
        
        return OAAppSettings.sharedManager().registerBooleanPreference(prefId, defValue: false).makeProfile()
    }
    
    private func registerMeasuredIntervalPref(_ customId: String?) -> OACommonLong {
        let prefId: String
        if let id = customId, !id.isEmpty {
            prefId = Self.measuredIntervalPrefKey + id
        } else {
            prefId = Self.measuredIntervalPrefKey
        }
        
        return OAAppSettings.sharedManager().registerLongPreference(prefId, defValue: Self.defaultIntervalMillis).makeProfile()
    }
    
    private func resetAverageValue() {
        widgetComputer?.resetLocations()
        setText("—", subtext: nil)
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
        
        configureShadowButtonMenu()
    }
    
    func supportsAverageMode() -> Bool {
        switch widgetType {
        case .OBDSpeed, .OBDCalculatedEngineLoad, .OBDFuelPressure, .OBDThrottlePosition, .OBDBatteryVoltage, .OBDAirIntakeTemp, .engineOilTemperature, .OBDAmbientAirTemp, .OBDEngineCoolantTemp:
            return true
        default:
            return false
        }
    }
    
    func isTemperatureWidget() -> Bool {
        switch widgetType {
        case .OBDAirIntakeTemp, .engineOilTemperature, .OBDAmbientAirTemp, .OBDEngineCoolantTemp:
            return true
        default:
            return false
        }
    }
    
    func getWidgetOBDCommand() -> OBDCommand? {
        fieldType?.requiredCommand
    }
}

extension OBDTextWidget {
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
