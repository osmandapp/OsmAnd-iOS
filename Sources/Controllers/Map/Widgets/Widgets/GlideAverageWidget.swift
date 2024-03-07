//
//  GlideAverageWidget.swift
//  OsmAnd Maps
//
//  Created by Skalii on 04.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAGlideAverageWidget)
@objcMembers
final class GlideAverageWidget: GlideBaseWidget {

    static let measuredIntervalPrefID = "average_glide_measured_interval_millis"
    private static var availableIntervals: [Int: String] = getAvailableIntervals()

    private let averageGlideComputer = AverageGlideComputer.shared
    private var measuredIntervalPref: OACommonLong
    private var cachedFormattedGlideRatio: String?

    init(customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        measuredIntervalPref = Self.registerMeasuredIntervalPref(customId)
        super.init(WidgetType.glideAverage, customId: customId, appMode: appMode, widgetParams: widgetParams)
        updateInfo()
        setIcon("widget_glide_ratio_average")
    }

    override init(frame: CGRect) {
        measuredIntervalPref = Self.registerMeasuredIntervalPref(nil)
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func getSettingsData(_ appMode: OAApplicationMode) -> OATableDataModel? {
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("average_glide_ratio_time_interval_desc")

        let settingRow = section.createNewRow()
        settingRow.cellType = OAValueTableViewCell.reuseIdentifier
        settingRow.key = "value_pref"
        settingRow.title = localizedString("shared_string_interval")
        settingRow.descr = localizedString("shared_string_interval")
        settingRow.setObj(measuredIntervalPref, forKey: "pref")
        settingRow.setObj(Self.getIntervalTitle(measuredIntervalPref.get(appMode)), forKey: "value")
        settingRow.setObj(getPossibleValues(measuredIntervalPref), forKey: "possible_values")
        settingRow.setObj(localizedString("average_glide_time_interval_desc"), forKey: "footer")

        return data
    }

    private func getPossibleValues(_ pref: OACommonPreference) -> [OATableRowData] {
        var rows = [OATableRowData]()
        if pref.key.hasPrefix(Self.measuredIntervalPrefID) {
            let valuesRow = OATableRowData()
            valuesRow.key = "values"
            valuesRow.cellType = OASegmentSliderTableViewCell.getIdentifier()
            valuesRow.title = localizedString("shared_string_interval")
            valuesRow.setObj(Self.availableIntervals, forKey: "values")
            rows.append(valuesRow)
        }
        return rows
    }

    static func getIntervalTitle(_ intervalValue: Int) -> String {
        return availableIntervals[intervalValue] ?? "-"
    }

    private static func getAvailableIntervals() -> [Int: String] {
        var intervals = [Int: String]()
        for interval in AverageValueComputer.measuredIntervals {
            let seconds = interval < 60 * 1000
            let timeInterval = seconds ? String(interval / 1000) : String(interval / 1000 / 60)
            let timeUnit = interval < 60 * 1000 ? localizedString("shared_string_sec") : localizedString("int_min")
            let formattedInterval = String(format: localizedString("ltr_or_rtl_combine_via_space"), arguments: [timeInterval, timeUnit])
            intervals[interval] = formattedInterval
        }
        return intervals
    }

    func getMeasuredInterval(_ appMode: OAApplicationMode) -> Int {
        return measuredIntervalPref.get(appMode)
    }

    func setMeasuredInterval(_ appMode: OAApplicationMode, measuredInterval: Int) {
        measuredIntervalPref.set(measuredInterval, mode: appMode)
    }

    override func updateInfo() -> Bool {
        if isTimeToUpdate() {
            let measuredInterval: Int = measuredIntervalPref.get()
            let ratio: String? = averageGlideComputer.getFormattedAverageGlideRatio(measuredInterval)
            if ratio != cachedFormattedGlideRatio {
                cachedFormattedGlideRatio = ratio
                if let ratio, !ratio.isEmpty {
                    setText(ratio, subtext: "")
                } else {
                    setText("-", subtext: "")
                }
            }
        }
        return true
    }

    override func copySettings(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerMeasuredIntervalPref(customId).set(measuredIntervalPref.get(appMode), mode: appMode)
    }

    private static func registerMeasuredIntervalPref(_ customId: String?) -> OACommonLong {
        var prefId: String
        if let customId, !customId.isEmpty {
            prefId = Self.measuredIntervalPrefID + customId
        } else {
            prefId = Self.measuredIntervalPrefID
        }
        return OAAppSettings.sharedManager().registerLongPreference(prefId, defValue: Int(AverageValueComputer.defaultIntervalMillis))
    }
}
