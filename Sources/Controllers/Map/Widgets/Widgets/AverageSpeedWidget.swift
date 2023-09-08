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
class AverageSpeedWidget: OATextInfoWidget {
    
    private static let MEASURED_INTERVAL_PREF_ID = "average_speed_measured_interval_millis"
    private static let SKIP_STOPS_PREF_ID = "average_speed_skip_stops"
    
    private static let UPDATE_INTERVAL_MILLIS = 1000
    private static let DASH = "—"
    
    private let averageSpeedComputer = OAAverageSpeedComputer.sharedInstance()
    
    private let measuredIntervalPref: OACommonLong
    private let skipStopsPref: OACommonBoolean
    private var customId: String? = nil

    private var lastUpdateTime = 0

    private var availableIntervals: [Int: String] = getAvailableIntervals()

    init(customId: String?) {
        self.customId = customId
        measuredIntervalPref = Self.registerMeasuredIntervalPref(customId)
        skipStopsPref = Self.registerSkipStopsPref(customId)
        super.init(type: .averageSpeed)
        setIcons(.averageSpeed)
        self.setMetricSystemDepended(true)
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
        return skipStopsPref.get(appMode)
    }
    
    func setShouldSkipStops(_ appMode: OAApplicationMode, skipStops: Bool) {
        skipStopsPref.set(skipStops, mode: appMode)
    }
    
    override func updateInfo() -> Bool {
        let time = Int(Date.now.timeIntervalSince1970 * 1000)
        if (isUpdateNeeded() || time - lastUpdateTime > Self.UPDATE_INTERVAL_MILLIS) {
            lastUpdateTime = time
            updateAverageSpeed()
            return true
        }
        return false
    }

    override func getSettingsData(_ appMode: OAApplicationMode) -> OATableDataModel? {
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")

        let settingRow = section.createNewRow()
        settingRow.cellType = OAValueTableViewCell.getIdentifier()
        settingRow.key = "value_pref"
        settingRow.title = localizedString("shared_string_interval")
        settingRow.iconName = nil // TODO
        settingRow.descr = localizedString("average_speed_time_interval_desc")
        settingRow.setObj(getIntervalTitle(measuredIntervalPref.get(appMode)), forKey: "value")
        settingRow.setObj(getPossibleValues(measuredIntervalPref), forKey: "possible_values")

        let compassRow = section.createNewRow()
        compassRow.cellType = OASwitchTableViewCell.getIdentifier()
        compassRow.title = localizedString("average_speed_skip_stops")
        compassRow.iconName = nil // TODO
        compassRow.setObj(skipStopsPref, forKey: "pref")

        return data
    }

    private func getPossibleValues(_ pref: OACommonPreference) -> [OATableRowData] {
        var rows = [OATableRowData]()
        for interval in availableIntervals.keys.sorted(by: { $0 < $1 }) {
            let row = OATableRowData()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.setObj(interval, forKey: "value")
            row.setObj(pref, forKey: "pref")
            row.title = availableIntervals[interval]
            rows.append(row)
        }
        return rows
    }

    private func getIntervalTitle(_ intervalValue: Int) -> String {
        return availableIntervals[intervalValue] ?? "-"
    }

    private static func getAvailableIntervals() -> [Int: String] {
        var intervals =  [Int: String]()
        for intervalNum in OAAverageSpeedComputer.measured_INTERVALS() {
            let interval = intervalNum.intValue
            let seconds = interval < 60 * 1000
            let timeInterval = seconds ? String(interval / 1000) : String(interval / 1000 / 60)
            let timeUnit = interval < 60 * 1000 ? localizedString("shared_string_sec") : localizedString("short_min")
            let formattedInterval = String(format: localizedString("ltr_or_rtl_combine_via_space"), arguments: [timeInterval, timeUnit])
            intervals[interval] = formattedInterval
        }
        return intervals
    }

    func updateAverageSpeed() {
        let measuredInterval = measuredIntervalPref.get()
        let skipLowSpeed = skipStopsPref.get()
        let averageSpeed = averageSpeedComputer.getAverageSpeed(measuredInterval, skipLowSpeed: skipLowSpeed)
        if (averageSpeed.isNaN) {
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
    
    static func registerMeasuredIntervalPref(_ customId: String?) -> OACommonLong {
        let settings = OAAppSettings.sharedManager()!
        let prefId = customId == nil || customId!.isEmpty
        ? Self.MEASURED_INTERVAL_PREF_ID
        : Self.MEASURED_INTERVAL_PREF_ID + customId!
        return settings.registerLongPreference(prefId, defValue: OAAverageSpeedComputer.default_INTERVAL_MILLIS())
    }
    
    static func registerSkipStopsPref(_ customId: String?) -> OACommonBoolean {
        let settings = OAAppSettings.sharedManager()!
        let prefId = customId == nil || customId!.isEmpty ? Self.SKIP_STOPS_PREF_ID : Self.SKIP_STOPS_PREF_ID + customId!
        return settings.registerBooleanPreference(prefId, defValue: true)
    }
}
