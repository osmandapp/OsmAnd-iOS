//
//  TripRecordingElevationWidget.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 26.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class TripRecordingElevationWidget: BaseRecordingWidget {
    private var isUphillType: Bool
    private var widgetState: TripRecordingElevationWidgetState?
    private var cachedElevationDiff: Double = -1
    private var cachedLastElevation: Double = -1
    private var forceUpdate = false
    
    init(isUphillType: Bool, widgetType: WidgetType, customId: String?, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        self.isUphillType = isUphillType
        super.init(type: widgetType)
        self.widgetState = TripRecordingElevationWidgetState(isUphillType: isUphillType, customId: customId, widgetType: widgetType, widgetParams: widgetParams)
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        updateInfo()
        onClickFunction = { [weak self] _ in
            guard let self else { return }
            self.forceUpdate = true
            self.widgetState?.changeToNextState()
            self.updateInfo()
        }
    }
    
    override init(frame: CGRect) {
        self.isUphillType = false
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult override func updateInfo() -> Bool {
        super.updateInfo()
        let elevationDiff = getElevationDiff()
        let lastElevation = getLastElevation()
        if isUpdateNeeded() || cachedElevationDiff != elevationDiff || cachedLastElevation != lastElevation {
            cachedElevationDiff = elevationDiff
            cachedLastElevation = lastElevation
            let altitudeMetrics = OAAppSettings.sharedManager().altitudeMetric.get()
            let mode = currentMode()
            let valueToFormat = mode == .total ? elevationDiff : lastElevation
            let (value, unit) = formatAltitude(valueToFormat, metrics: altitudeMetrics)
            setText(value, subtext: unit)
            forceUpdate = false
        }
        
        updateTitleAndIcon()
        return true
    }
    
    override func getSettingsData(_ appMode: OAApplicationMode, widgetConfigurationParams: [String: Any]?, isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()
        guard let pref = widgetState?.getElevationModePreference() else { return data }
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")
        let modeRow = section.createNewRow()
        modeRow.cellType = OAButtonTableViewCell.reuseIdentifier
        modeRow.key = "recording_widget_mode_key"
        modeRow.title = localizedString("shared_string_mode")
        modeRow.setObj(pref, forKey: "pref")
        var currentRaw = TripRecordingElevationMode.total.rawValue
        if isCreate, let widgetConfigurationParams, let str = widgetConfigurationParams[pref.key] as? String, let v = Int(str) {
            currentRaw = v
        } else if !isCreate {
            currentRaw = Int(pref.get(appMode))
        }
        
        let currentMode = TripRecordingElevationMode(rawValue: currentRaw) ?? .total
        modeRow.setObj(localizedString(currentMode.titleKey(isUphill: isUphillType)), forKey: "value")
        let possibleValues: [OATableRowData] = [TripRecordingElevationMode.total, .last].map { mode in
            let row = OATableRowData()
            row.cellType = OASimpleTableViewCell.reuseIdentifier
            row.setObj(mode.rawValue, forKey: "value")
            row.title = localizedString(mode.titleKey(isUphill: isUphillType))
            return row
        }
        
        modeRow.setObj(possibleValues, forKey: "possible_values")
        return data
    }
    
    override func getIconName() -> String? {
        widgetState?.getModeIconName()
    }
    
    override func isMetricSystemDepended() -> Bool {
        true
    }
    
    override func isAltitudeMetricDepended() -> Bool {
        true
    }
    
    override func isUpdateNeeded() -> Bool {
        forceUpdate || super.isUpdateNeeded()
    }
    
    override func resolvedModeTitleKeyForList() -> String? {
        widgetState?.getModeTitleKey() ?? TripRecordingElevationMode.total.titleKey(isUphill: isUphillType)
    }
    
    func setIsUphillType(_ value: Bool) {
        isUphillType = value
    }
    
    func elevationModePreference() -> OACommonInteger? {
        widgetState?.getElevationModePreference()
    }
    
    func getElevationDiff() -> Double {
        fatalError("getElevationDiff() must be overridden in subclass")
    }
    
    func getLastElevation() -> Double {
        fatalError("getLastElevation() must be overridden in subclass")
    }
    
    private func updateTitleAndIcon() {
        let baseTitle = widgetType?.title ?? ""
        let modeTitleKey = widgetState?.getModeTitleKey() ?? TripRecordingElevationMode.total.titleKey(isUphill: isUphillType)
        let modeTitle = localizedString(modeTitleKey)
        let format = localizedString("ltr_or_rtl_combine_via_colon")
        let fullTitle = String(format: format, baseTitle, modeTitle)
        let iconName = widgetState?.getModeIconName() ?? widgetType?.iconName ?? ""
        setContentTitle(fullTitle)
        setIcon(iconName)
        configureSimpleLayout()
    }
    
    private func formatAltitude(_ alt: Double, metrics: EOAltitudeMetricsConstant) -> (value: String?, unit: String?) {
        let valueUnitArray = NSMutableArray()
        OAOsmAndFormatter.getFormattedAlt(alt, mc: metrics, valueUnitArray: valueUnitArray)
        let value = (valueUnitArray.firstObject as? String) ?? ""
        let unit = valueUnitArray.count > 1 ? valueUnitArray[1] as? String : nil
        return (value, unit)
    }
    
    private func currentMode() -> TripRecordingElevationMode {
        guard let pref = widgetState?.getElevationModePreference() else { return .total }
        return TripRecordingElevationMode(rawValue: Int(pref.get())) ?? .total
    }
}

@objcMembers
final class TripRecordingUphillWidget: TripRecordingElevationWidget {
    private var diffElevationUp: Double = 0.0
    
    init(customId: String?, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        super.init(isUphillType: true, widgetType: .tripRecordingUphill, customId: customId, appMode: appMode, widgetParams: widgetParams)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setIsUphillType(true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getElevationDiff() -> Double {
        guard let analysis = getAnalysis() else { return diffElevationUp }
        diffElevationUp = max(analysis.diffElevationUp, diffElevationUp)
        return diffElevationUp
    }
    
    override func getLastElevation() -> Double {
        guard let lastSlope = getLastSlope(isUphill: true) else { return 0.0 }
        return lastSlope.elevDiff
    }
    
    override func resetCachedValue() {
        super.resetCachedValue()
        diffElevationUp = 0.0
    }
}

@objcMembers
final class TripRecordingDownhillWidget: TripRecordingElevationWidget {
    private var diffElevationDown: Double = 0.0
    
    init(customId: String?, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        super.init(isUphillType: false, widgetType: .tripRecordingDownhill, customId: customId, appMode: appMode, widgetParams: widgetParams)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setIsUphillType(false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getElevationDiff() -> Double {
        guard let analysis = getAnalysis() else { return diffElevationDown }
        diffElevationDown = max(analysis.diffElevationDown, diffElevationDown)
        return diffElevationDown
    }
    
    override func getLastElevation() -> Double {
        guard let lastSlope = getLastSlope(isUphill: false) else { return 0.0 }
        return lastSlope.elevDiff
    }
    
    override func resetCachedValue() {
        super.resetCachedValue()
        diffElevationDown = 0.0
    }
}
