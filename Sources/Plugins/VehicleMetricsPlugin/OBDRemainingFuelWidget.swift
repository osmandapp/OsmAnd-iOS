//
//  OBDRemainingFuelWidget.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 19.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

private enum RemainingFuelMode: String, CaseIterable {
    case percent = "PERCENT"
    case volume = "VOLUME"
    case distance = "DISTANCE"
    
    var fieldType: OBDDataComputer.OBDTypeWidget {
        switch self {
        case .percent:
            return .fuelLeftPercent
        case .volume:
            return .fuelLeftLiter
        case .distance:
            return .fuelLeftKm
        }
    }
    
    func getTitle(appMode: OAApplicationMode) -> String {
        let settings = OAAppSettings.sharedManager()
        switch self {
        case .percent:
            return localizedString("percent_unit")
        case .volume:
            let left = localizedString("shared_string_volume")
            let unitKey = {
                switch settings?.volumeUnits.get(appMode) {
                case .LITRES:
                    return "litres"
                case .IMPERIAL_GALLONS:
                    return "imperial_gallons"
                case .US_GALLONS:
                    return "us_gallons"
                default:
                    return "litres"
                }
            }()
            
            return String(format: localizedString("ltr_or_rtl_combine_with_brackets"), left, localizedString(unitKey))
            
        case .distance:
            let left = localizedString("shared_string_distance")
            let unitKey = {
                switch settings?.metricSystem.get(appMode) {
                case .KILOMETERS_AND_METERS:
                    return "km"
                case .NAUTICAL_MILES_AND_METERS, .NAUTICAL_MILES_AND_FEET:
                    return "nm"
                default:
                    return "mile"
                }
            }()
            
            return String(format: localizedString("ltr_or_rtl_combine_with_brackets"), left, localizedString(unitKey))
        }
    }
}

@objcMembers
final class OBDRemainingFuelWidget: OBDTextWidget {
    private static let obdRemainingFuelModeKey = "obd_remaining_fuel_mode"
    private var remainingFuelModePref: OACommonString?
    
    convenience init(customId: String?, widgetType: WidgetType, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        self.init(frame: .zero)
        self.widgetType = widgetType
        self.plugin = OAPluginsHelper.getPlugin(VehicleMetricsPlugin.self) as? VehicleMetricsPlugin
        super.configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        self.remainingFuelModePref = registerRemainingFuelPref(customId, widgetParams: widgetParams, appMode: appMode)
        let typeWidget = getFieldType()
        self.widgetComputer = OBDDataComputer.shared.registerWidget(type: typeWidget, averageTimeSeconds: 0)
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
        modeRow.setObj(remainingFuelModePref as Any, forKey: "pref")
        let currentRaw: String = {
            guard let remainingFuelModePref else { return RemainingFuelMode.percent.rawValue }
            if isCreate, let widgetConfigurationParams, let overrideRaw = widgetConfigurationParams[remainingFuelModePref.key] as? String, RemainingFuelMode(rawValue: overrideRaw) != nil {
                return overrideRaw
            }

            return remainingFuelModePref.get(appMode) ?? RemainingFuelMode.percent.rawValue
        }()
        modeRow.setObj(currentRaw, forKey: "value")
        let options: [OATableRowData] = RemainingFuelMode.allCases.map { mode in
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
            if let widgetComputer, widgetComputer.type != typeWidget, widgetComputer.averageTimeSeconds != 0 {
                OBDDataComputer.shared.removeWidget(w: widgetComputer)
            }
            
            widgetComputer = OBDDataComputer.shared.registerWidget(type: typeWidget, averageTimeSeconds: 0)
        }
        
        updateInfo()
    }
    
    private func getFieldType() -> OBDDataComputer.OBDTypeWidget {
        if let raw = remainingFuelModePref?.get(), let mode = RemainingFuelMode(rawValue: raw) {
            return mode.fieldType
        }
        
        return RemainingFuelMode.percent.fieldType
    }
    
    private func nextMode() {
        guard let remainingFuelModePref else { return }
        let modes = RemainingFuelMode.allCases
        guard !modes.isEmpty else { return }
        let rawValue = remainingFuelModePref.get() ?? modes[0].rawValue
        let currentMode = RemainingFuelMode(rawValue: rawValue) ?? modes[0]
        guard let currentIndex = modes.firstIndex(of: currentMode) else { return }
        let nextMode = modes[(currentIndex + 1) % modes.count]
        remainingFuelModePref.set(nextMode.rawValue)
        updatePrefs(prefsChanged: true)
    }
    
    private func registerRemainingFuelPref(_ customId: String?, widgetParams: [String: Any]?, appMode: OAApplicationMode) -> OACommonString {
        let prefId: String
        if let customId, !customId.isEmpty {
            prefId = Self.obdRemainingFuelModeKey + customId
        } else {
            prefId = Self.obdRemainingFuelModeKey
        }
        
        guard let pref = OAAppSettings.sharedManager().registerStringPreference(prefId, defValue: RemainingFuelMode.percent.rawValue).makeProfile() else { fatalError("Failed to register preference \(prefId)") }
        if let widgetParams {
            if let raw = widgetParams[prefId] as? String, RemainingFuelMode(rawValue: raw) != nil {
                pref.set(raw, mode: appMode)
            } else if let base = widgetParams[Self.obdRemainingFuelModeKey] as? String, RemainingFuelMode(rawValue: base) != nil {
                pref.set(base, mode: appMode)
            }
        }
        
        return pref
    }
}
