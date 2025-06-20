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
        let volumeCase: EOAVolumeConstant = OAAppSettings.sharedManager().volumeUnits.get(appMode)
        let metricCase: EOAMetricsConstant = OAAppSettings.sharedManager().metricSystem.get(appMode)
        let leftText: String = {
            switch self {
            case .volume:
                return localizedString("shared_string_volume")
            case .distance:
                return localizedString("shared_string_distance")
            case .percent:
                return localizedString("percent_unit")
            }
        }()
        
        let rightText: String = {
            switch self {
            case .volume:
                let unitKey: String
                switch volumeCase {
                case .LITRES:
                    unitKey = "litres"
                case .IMPERIAL_GALLONS:
                    unitKey = "imperial_gallons"
                case .US_GALLONS:
                    unitKey = "us_gallons"
                default:
                    unitKey = "litres"
                }
                return localizedString(unitKey)
            case .distance:
                let unitKey: String
                switch metricCase {
                case .KILOMETERS_AND_METERS:
                    unitKey = "km"
                case .NAUTICAL_MILES_AND_METERS,
                        .NAUTICAL_MILES_AND_FEET:
                    unitKey = "nm"
                default:
                    unitKey = "mile"
                }
                return localizedString(unitKey)
            case .percent:
                return ""
            }
        }()
        
        if self == .percent {
            return leftText
        }
        
        return String(format: localizedString("ltr_or_rtl_combine_with_brackets"), leftText, rightText)
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
        _ = updateInfo()
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
            guard let pref = remainingFuelModePref else { return RemainingFuelMode.percent.rawValue }
            if isCreate, let params = widgetConfigurationParams, let overrideRaw = params[pref.key] as? String, RemainingFuelMode(rawValue: overrideRaw) != nil {
                return overrideRaw
            }

            return pref.get(appMode) ?? RemainingFuelMode.percent.rawValue
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
            if let wc = widgetComputer, wc.type != typeWidget, wc.averageTimeSeconds != 0 {
                OBDDataComputer.shared.removeWidget(w: wc)
            }
            
            widgetComputer = OBDDataComputer.shared.registerWidget(type: typeWidget, averageTimeSeconds: 0)
        }
        
        _ = updateInfo()
    }
    
    private func getFieldType() -> OBDDataComputer.OBDTypeWidget {
        if let raw = remainingFuelModePref?.get(), let mode = RemainingFuelMode(rawValue: raw) {
            return mode.fieldType
        }
        
        return RemainingFuelMode.percent.fieldType
    }
    
    private func nextMode() {
        guard let pref = remainingFuelModePref else { return }
        let modes = RemainingFuelMode.allCases
        guard !modes.isEmpty else { return }
        let rawValue = pref.get() ?? modes[0].rawValue
        let currentMode = RemainingFuelMode(rawValue: rawValue) ?? modes[0]
        guard let currentIndex = modes.firstIndex(of: currentMode) else { return }
        let nextMode = modes[(currentIndex + 1) % modes.count]
        pref.set(nextMode.rawValue)
        updatePrefs(prefsChanged: true)
    }
    
    private func registerRemainingFuelPref(_ customId: String?, widgetParams: [String: Any]?, appMode: OAApplicationMode) -> OACommonString {
        let prefId: String
        if let id = customId, !id.isEmpty {
            prefId = Self.obdRemainingFuelModeKey + id
        } else {
            prefId = Self.obdRemainingFuelModeKey
        }
        
        guard let pref = OAAppSettings.sharedManager().registerStringPreference(prefId, defValue: RemainingFuelMode.percent.rawValue).makeProfile() else { fatalError("Failed to register preference \(prefId)") }
        if let params = widgetParams {
            if let raw = params[prefId] as? String, RemainingFuelMode(rawValue: raw) != nil {
                pref.set(raw, mode: appMode)
            } else if let base = params[Self.obdRemainingFuelModeKey] as? String, RemainingFuelMode(rawValue: base) != nil {
                pref.set(base, mode: appMode)
            }
        }
        
        return pref
    }
}
