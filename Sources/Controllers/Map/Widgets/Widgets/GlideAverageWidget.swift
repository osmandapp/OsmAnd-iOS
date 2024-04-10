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

    private let widgetState: GlideAverageWidgetState?
    private let averageGlideComputer = AverageGlideComputer.shared
    private var measuredIntervalPref: OACommonLong
    private var cachedFormattedGlideRatio: String?
    private var forceUpdate = false // Becomes 'true' when widget state switches

    init(with widgetState: GlideAverageWidgetState, customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        self.widgetState = widgetState
        measuredIntervalPref = Self.registerMeasuredIntervalPref(customId)
        super.init(WidgetType.glideAverage, customId: customId, appMode: appMode, widgetParams: widgetParams)
        updateInfo()
        onClickFunction = { [weak self] _ in
            guard let self else { return }

            forceUpdate = true
            self.widgetState?.changeToNextState()
            updateInfo()
            setContentTitle(getWidgetName())
            setIcon(getWidgetIcon())
        }
        setContentTitle(getWidgetName())
        setIcon(getWidgetIcon())
    }

    override init(frame: CGRect) {
        measuredIntervalPref = Self.registerMeasuredIntervalPref(nil)
        widgetState = GlideAverageWidgetState(nil)
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func getWidgetState() -> OAWidgetState? {
        return widgetState
    }

    override func getSettingsData(_ appMode: OAApplicationMode) -> OATableDataModel? {
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")

        if let preference = widgetState?.getPreference() {
            let settingRow = section.createNewRow()
            settingRow.cellType = OAValueTableViewCell.reuseIdentifier
            settingRow.key = "value_pref"
            settingRow.title = localizedString("shared_string_mode")
            settingRow.setObj(preference, forKey: "pref")
            settingRow.setObj(getWidgetName() ?? localizedString("average_glide_ratio"), forKey: "value")
            settingRow.setObj(getPossibleValues(preference), forKey: "possible_values")
            settingRow.setObj(localizedString("time_to_navigation_point_widget_settings_desc"), forKey: "footer")
        }

        let settingRow = section.createNewRow()
        settingRow.cellType = OAValueTableViewCell.reuseIdentifier
        settingRow.key = "value_pref"
        settingRow.title = localizedString("shared_string_interval")
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
        } else {
            for i in 0..<2 {
                let row = OATableRowData()
                row.cellType = OASimpleTableViewCell.getIdentifier()
                row.setObj(i == 0 ? "false" : "true", forKey: "value")
                row.title = localizedString(i == 0 ? "average_glide_ratio" : "average_vertical_speed")
                rows.append(row)
            }
        }
        return rows
    }

    static func getIntervalTitle(_ intervalValue: Int) -> String {
        availableIntervals[intervalValue] ?? "-"
    }

    private static func getAvailableIntervals() -> [Int: String] {
        var intervals = [Int: String]()
        for interval in AverageValueComputer.measuredIntervals {
            let seconds = interval < 60 * 1000
            let timeInterval = seconds ? String(interval / 1000) : String(interval / 1000 / 60)
            let timeUnit = localizedString(interval < 60 * 1000 ? "shared_string_sec" : "int_min")
            let formattedInterval = String(format: localizedString("ltr_or_rtl_combine_via_space"), arguments: [timeInterval, timeUnit])
            intervals[interval] = formattedInterval
        }
        return intervals
    }

    func getWidgetName() -> String? {
        guard widgetState != nil else {
            return widgetType?.title
        }
        return localizedString(isInVerticalSpeedState() ? "average_vertical_speed" : "average_glide_ratio")
    }

    func getWidgetIcon() -> String? {
        guard widgetState != nil else {
            return widgetType?.iconName
        }
        return localizedString(isInVerticalSpeedState() ? "widget_vertical_average_speed" : "widget_glide_ratio_average")
    }

    func getMeasuredInterval(_ appMode: OAApplicationMode) -> Int {
        measuredIntervalPref.get(appMode)
    }

    func setMeasuredInterval(_ appMode: OAApplicationMode, measuredInterval: Int) {
        measuredIntervalPref.set(measuredInterval, mode: appMode)
    }

    override func updateInfo() -> Bool {
        if isTimeToUpdate() || forceUpdate {
            let measuredInterval: Int = measuredIntervalPref.get()
            let ratio: String? = averageGlideComputer.getFormattedAverage(verticalSpeed: isInVerticalSpeedState(), measuredInterval: measuredInterval)
            if ratio != cachedFormattedGlideRatio {
                cachedFormattedGlideRatio = ratio
                if let ratio, !ratio.isEmpty {
                    if isInVerticalSpeedState() {
                        let components = ratio.components(separatedBy: " ")
                        let numberPart = components.dropLast().joined(separator: " ")
                        let unitPart = components.last ?? ""
                        setText(numberPart, subtext: unitPart)
                    } else {
                        setText(ratio, subtext: "")
                    }
                } else {
                    setText("-", subtext: "")
                }
            }
            forceUpdate = false
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

    func isInVerticalSpeedState() -> Bool {
        widgetState?.getPreference().get() ?? false
    }
}
