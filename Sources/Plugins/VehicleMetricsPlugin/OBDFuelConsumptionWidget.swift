//
//  OBDFuelConsumptionWidget.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

private enum FuelConsumptionMode: String, CaseIterable {
    case unitsPerVolume = "UNITS_PER_VOLUME"
    case volumePer100Units = "VOLUME_PER_100_UNITS"
    case volumePerHour = "VOLUME_PER_HOUR"
    
    var fieldType: OBDDataComputer.OBDTypeWidget {
        switch self {
        case .unitsPerVolume: .fuelConsumptionRateMPerLiter
        case .volumePer100Units: .fuelConsumptionRateLiterKm
        case .volumePerHour: .fuelConsumptionRateLiterHour
        }
    }
    
    func getTitle(appMode: OAApplicationMode) -> String {
        let settings = OAAppSettings.sharedManager()
        let leftText: String
        let rightText: String
        if self == .unitsPerVolume {
            let unitKey: String
            switch settings.metricSystem.get(appMode) {
            case .KILOMETERS_AND_METERS:
                unitKey = "kilometers"
            case .NAUTICAL_MILES_AND_METERS, .NAUTICAL_MILES_AND_FEET:
                unitKey = "si_nm"
            default:
                unitKey = "miles"
            }
            
            leftText = localizedString(unitKey)
            rightText = OAVolumeConstant.toSingleHumanString(settings.volumeUnits.get(appMode))
        } else if self == .volumePer100Units {
            leftText = OAVolumeConstant.toHumanString(settings.volumeUnits.get(appMode))
            
            let unitKey: String
            switch settings.metricSystem.get(appMode) {
            case .KILOMETERS_AND_METERS:
                unitKey = "kilometers"
            case .NAUTICAL_MILES_AND_METERS, .NAUTICAL_MILES_AND_FEET:
                unitKey = "si_nm"
            default:
                unitKey = "miles"
            }
            
            rightText = String(format: localizedString("ltr_or_rtl_combine_via_space"), "100", localizedString(unitKey))
        } else {
            leftText = OAVolumeConstant.toHumanString(settings.volumeUnits.get(appMode))
            rightText = localizedString("shared_string_hour").lowercased()
        }
        
        return String(format: localizedString("ltr_or_rtl_combine_via_per"), leftText, rightText)
    }
}

@objcMembers
final class OBDFuelConsumptionWidget: OBDTextWidget {
    private static let obdFuelConsumptionModeKey = "obd_fuel_consumption_mode"
    private static let fuelConsumptionAverageTimeSeconds: Int32 = 5 * 60
    private var fuelConsumptionModePref: OACommonString?
    private var defaultMode: FuelConsumptionMode {
        OAAppSettings.sharedManager().volumeUnits.get() == .LITRES ? .volumePer100Units : .unitsPerVolume
    }
    
    convenience init(customId: String?, widgetType: WidgetType, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        self.init(frame: .zero)
        self.widgetType = widgetType
        self.plugin = OAPluginsHelper.getPlugin(VehicleMetricsPlugin.self) as? VehicleMetricsPlugin
        super.configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        self.fuelConsumptionModePref = registerFuelConsumptionPref(customId, widgetParams: widgetParams, appMode: appMode)
        let typeWidget = getFieldType()
        self.widgetComputer = OBDDataComputer.shared.registerWidget(type: typeWidget, averageTimeSeconds: getAverageTime(for: typeWidget))
        updateInfo()
        setIconFor(widgetType)
        onClickFunction = { [weak self] _ in
            guard let self else { return }
            self.nextMode()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getSettingsData(_ appMode: OAApplicationMode, widgetConfigurationParams: [String: Any]?, isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")
        let modeRow = section.createNewRow()
        modeRow.cellType = OAButtonTableViewCell.reuseIdentifier
        modeRow.key = "fuel_consumption_mode_key"
        modeRow.title = localizedString("shared_string_mode")
        modeRow.setObj(fuelConsumptionModePref as Any, forKey: "pref")
        let currentRaw: String = {
            guard let fuelConsumptionModePref else { return defaultMode.rawValue }
            if isCreate, let widgetConfigurationParams, let overrideRaw = widgetConfigurationParams[fuelConsumptionModePref.key] as? String, FuelConsumptionMode(rawValue: overrideRaw) != nil {
                return overrideRaw
            }
            return isCreate ? defaultMode.rawValue : fuelConsumptionModePref.get(appMode)
        }()
        modeRow.setObj(currentRaw, forKey: "value")
        let options: [OATableRowData] = FuelConsumptionMode.allCases.map { mode in
            let row = OATableRowData()
            row.cellType = OASimpleTableViewCell.reuseIdentifier
            row.setObj(mode.rawValue, forKey: "value")
            row.title = mode.getTitle(appMode: appMode)
            return row
        }
        modeRow.setObj(options, forKey: "possible_values")
        return data
    }
    
    override func updatePrefs(prefsChanged: Bool) {
        super.updatePrefs(prefsChanged: prefsChanged)
        let typeWidget = getFieldType()
        if prefsChanged {
            if let widgetComputer, widgetComputer.type != typeWidget, widgetComputer.averageTimeSeconds != 0, widgetComputer.averageTimeSeconds != typeWidget.defaultAverageTime, typeWidget != .fuelConsumptionRatePercentHour, typeWidget != .fuelConsumptionRateLiterHour, typeWidget != .fuelConsumptionRateLiterKm {
                OBDDataComputer.shared.removeWidget(w: widgetComputer)
            }
            
            widgetComputer = OBDDataComputer.shared.registerWidget(type: typeWidget, averageTimeSeconds: getAverageTime(for: typeWidget))
        }
        
        updateInfo()
    }
    
    private func getFieldType() -> OBDDataComputer.OBDTypeWidget {
        guard let raw = fuelConsumptionModePref?.get(), let mode = FuelConsumptionMode(rawValue: raw) else { return defaultMode.fieldType }
        
        return mode.fieldType
    }
    
    private func nextMode() {
        guard let fuelConsumptionModePref else { return }
        let modes = FuelConsumptionMode.allCases
        guard !modes.isEmpty else { return }
        let rawValue = fuelConsumptionModePref.get()
        let currentMode = FuelConsumptionMode(rawValue: rawValue) ?? modes[0]
        guard let currentIndex = modes.firstIndex(of: currentMode) else { return }
        let nextMode = modes[(currentIndex + 1) % modes.count]
        fuelConsumptionModePref.set(nextMode.rawValue)
        updatePrefs(prefsChanged: true)
    }
    
    private func getAverageTime(for type: OBDDataComputer.OBDTypeWidget) -> Int32 {
        switch type {
        case .fuelConsumptionRatePercentHour, .fuelConsumptionRateLiterHour, .fuelConsumptionRateLiterKm:
            return Self.fuelConsumptionAverageTimeSeconds
        default:
            return 0
        }
    }
    
    private func registerFuelConsumptionPref(_ customId: String?, widgetParams: [String: Any]?, appMode: OAApplicationMode) -> OACommonString {
        let prefId: String
        if let customId, !customId.isEmpty {
            prefId = Self.obdFuelConsumptionModeKey + customId
        } else {
            prefId = Self.obdFuelConsumptionModeKey
        }
        
        let pref = OAAppSettings.sharedManager().registerStringPreference(prefId, defValue: defaultMode.rawValue).makeProfile()
        if let widgetParams {
            if let raw = widgetParams[prefId] as? String, FuelConsumptionMode(rawValue: raw) != nil {
                pref.set(raw, mode: appMode)
            } else if let base = widgetParams[Self.obdFuelConsumptionModeKey] as? String, FuelConsumptionMode(rawValue: base) != nil {
                pref.set(base, mode: appMode)
            }
        }
        
        return pref
    }
}
