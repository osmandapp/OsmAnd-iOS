//
//  AverageSpeedWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 18.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAAverageSpeedWidget)
@objcMembers
final class AverageSpeedWidget: OASimpleWidget {
    static let MEASURED_INTERVAL_PREF_ID = "average_speed_measured_interval_millis"
    static let SKIP_STOPS_PREF_ID = "average_speed_skip_stops"
    
    private static let UPDATE_INTERVAL_MILLIS = 1000
    private static let DASH = "—"
    
    private let averageSpeedComputer = OAAverageSpeedComputer.sharedInstance()
    
    private var measuredIntervalPref: OACommonLong
    private var skipStopsPref: OACommonBoolean
    private var customId: String?

    private var lastUpdateTime = 0

    private static var availableIntervals: [Int: String] = getAvailableIntervals()

    convenience init(customId: String?, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        self.init(frame: .zero)
        
        widgetType = .averageSpeed
        setIconFor(widgetType)
        setMetricSystemDepended(true)
        
        self.customId = customId
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        measuredIntervalPref = Self.registerMeasuredIntervalPref(customId, appMode: appMode, widgetParams: widgetParams)
        skipStopsPref = Self.registerSkipStopsPref(customId, appMode: appMode, widgetParams: widgetParams)
    }
    
    override init(frame: CGRect) {
        measuredIntervalPref = Self.registerMeasuredIntervalPref(customId)
        skipStopsPref = Self.registerSkipStopsPref(customId)
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getMeasuredInterval(_ appMode: OAApplicationMode) -> Int {
        measuredIntervalPref.get(appMode)
    }
    
    func setMeasuredInterval(_ appMode: OAApplicationMode, measuredInterval: Int) {
        measuredIntervalPref.set(measuredInterval, mode: appMode)
    }
    
    func shouldSkipStops(_ appMode: OAApplicationMode) -> Bool {
        skipStopsPref.get(appMode)
    }
    
    func setShouldSkipStops(_ appMode: OAApplicationMode, skipStops: Bool) {
        skipStopsPref.set(skipStops, mode: appMode)
    }
    
    override func updateInfo() -> Bool {
        let time = Int(Date.now.timeIntervalSince1970 * 1000)
        if isUpdateNeeded() || time - lastUpdateTime > Self.UPDATE_INTERVAL_MILLIS {
            lastUpdateTime = time
            updateAverageSpeed()
            return true
        }
        return false
    }
    
    override func getSettingsData(_ appMode: OAApplicationMode,
                                  widgetConfigurationParams: [String: Any]?,
                                  isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")

        let settingRow = section.createNewRow()
        settingRow.cellType = OAValueTableViewCell.getIdentifier()
        settingRow.key = "value_pref"
        settingRow.title = localizedString("shared_string_interval")
        settingRow.setObj(measuredIntervalPref, forKey: "pref")
        
        var currentValue = OAAverageSpeedComputer.default_INTERVAL_MILLIS()
        if let widgetConfigurationParams,
           let key = widgetConfigurationParams.keys.first(where: { $0.hasPrefix(Self.MEASURED_INTERVAL_PREF_ID) }),
           let value = widgetConfigurationParams[key] as? String,
           let widgetValue = Int(value) {
            currentValue = widgetValue
        } else if !isCreate {
            currentValue = measuredIntervalPref.get(appMode)
        }
        settingRow.setObj(Self.getIntervalTitle(currentValue), forKey: "value")
        
        settingRow.setObj(getPossibleValues(), forKey: "possible_values")
        settingRow.setObj(localizedString("average_speed_time_interval_desc"), forKey: "footer")

        let compassRow = section.createNewRow()
        compassRow.cellType = OASwitchTableViewCell.getIdentifier()
        compassRow.title = localizedString("average_speed_skip_stops")
        compassRow.setObj(skipStopsPref, forKey: "pref")

        return data
    }

    private func getPossibleValues() -> [OATableRowData] {
        var rows = [OATableRowData]()
        let valuesRow = OATableRowData()
        valuesRow.key = "values"
        valuesRow.cellType = OASegmentSliderTableViewCell.getIdentifier()
        valuesRow.title = localizedString("shared_string_interval")
        valuesRow.setObj(Self.availableIntervals, forKey: "values")
        rows.append(valuesRow)
        return rows
    }

    static func getIntervalTitle(_ intervalValue: Int) -> String {
        availableIntervals[intervalValue] ?? "-"
    }

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

    func updateAverageSpeed() {
        let measuredInterval = measuredIntervalPref.get()
        let skipLowSpeed = skipStopsPref.get()
        let averageSpeed = averageSpeedComputer.getAverageSpeed(measuredInterval, skipLowSpeed: skipLowSpeed)
        if averageSpeed.isNaN {
            setText(Self.DASH, subtext: nil)
        } else {
            let formattedAverageSpeed = OAOsmAndFormatter.getFormattedSpeed(averageSpeed).components(separatedBy: " ")
            setText(formattedAverageSpeed.first, subtext: formattedAverageSpeed.count > 1 ? formattedAverageSpeed.last : nil)
        }
    }
    
    override func copySettings(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerMeasuredIntervalPref(customId).set(measuredIntervalPref.get(appMode), mode: appMode)
        Self.registerSkipStopsPref(customId).set(skipStopsPref.get(appMode), mode: appMode)
    }
    
    static func registerMeasuredIntervalPref(_ customId: String?,
                                             appMode: OAApplicationMode? = nil,
                                             widgetParams: ([String: Any])? = nil) -> OACommonLong {
        let settings = OAAppSettings.sharedManager()!
        let prefId = customId == nil || customId!.isEmpty
        ? Self.MEASURED_INTERVAL_PREF_ID
        : Self.MEASURED_INTERVAL_PREF_ID + customId!
        
        let preference = settings.registerLongPreference(prefId, defValue: OAAverageSpeedComputer.default_INTERVAL_MILLIS())!
        if let appMode, let string = widgetParams?[Self.MEASURED_INTERVAL_PREF_ID] as? String, let widgetValue = Int(string) {
            preference.set(widgetValue, mode: appMode)
        }
        return preference
    }
    
    static func registerSkipStopsPref(_ customId: String?, appMode: OAApplicationMode? = nil, widgetParams: ([String: Any])? = nil) -> OACommonBoolean {
        let settings = OAAppSettings.sharedManager()!
        let prefId = customId == nil || customId!.isEmpty ? Self.SKIP_STOPS_PREF_ID : Self.SKIP_STOPS_PREF_ID + customId!
        
        let preference = settings.registerBooleanPreference(prefId, defValue: true)!
        if let appMode, let widgetValue = widgetParams?[Self.SKIP_STOPS_PREF_ID] as? Bool {
            preference.set(widgetValue, mode: appMode)
        }
        return preference
    }
}
