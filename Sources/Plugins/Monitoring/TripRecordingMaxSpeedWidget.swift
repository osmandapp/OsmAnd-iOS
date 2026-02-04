//
//  TripRecordingMaxSpeedWidget.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 24.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class TripRecordingMaxSpeedWidget: BaseRecordingWidget {
    private var widgetState: TripRecordingMaxSpeedWidgetState?
    private var cachedMaxSpeed: Double = -1
    private var lastMaxSpeed: Int = 0
    private var forceUpdate = false
    
    init(customId: String?, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        super.init(type: .tripRecordingMaxSpeed)
        self.widgetState = TripRecordingMaxSpeedWidgetState(customId: customId, widgetType: .tripRecordingMaxSpeed, widgetParams: widgetParams)
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
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult override func updateInfo() -> Bool {
        super.updateInfo()
        let maxSpeed = getMaxSpeed()
        if forceUpdate || isUpdateNeeded() || cachedMaxSpeed != maxSpeed {
            cachedMaxSpeed = maxSpeed
            forceUpdate = false
            let formatted = OAOsmAndFormatter.getFormattedSpeed(Float(maxSpeed)).components(separatedBy: " ")
            let value = formatted.first
            let unit = formatted.count > 1 ? formatted.last : nil
            setText(value, subtext: unit)
        }
        
        updateTitleAndIcon()
        return true
    }
    
    override func getSettingsData(_ appMode: OAApplicationMode, widgetConfigurationParams: [String: Any]?, isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()
        guard let pref = widgetState?.getMaxSpeedModePreference() else { return data }
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")
        let modeRow = section.createNewRow()
        modeRow.cellType = OAButtonTableViewCell.reuseIdentifier
        modeRow.key = "recording_widget_mode_key"
        modeRow.title = localizedString("shared_string_mode")
        modeRow.setObj(pref, forKey: "pref")
        var currentRaw = MaxSpeedMode.total.rawValue
        if isCreate, let widgetConfigurationParams, let str = widgetConfigurationParams[pref.key] as? String, let v = Int(str) {
            currentRaw = v
        } else if !isCreate {
            currentRaw = Int(pref.get(appMode))
        }
        
        let currentMode = MaxSpeedMode(rawValue: currentRaw) ?? .total
        modeRow.setObj(localizedString(currentMode.titleKey), forKey: "value")
        let possibleValues: [OATableRowData] = [MaxSpeedMode.total, .lastDownhill, .lastUphill].map { mode in
            let row = OATableRowData()
            row.cellType = OASimpleTableViewCell.reuseIdentifier
            row.setObj(mode.rawValue, forKey: "value")
            row.title = localizedString(mode.titleKey)
            return row
        }
        
        modeRow.setObj(possibleValues, forKey: "possible_values")
        return data
    }
    
    override func getIconName() -> String? {
        currentMode().iconName
    }
    
    override func resetCachedValue() {
        super.resetCachedValue()
        lastMaxSpeed = 0
    }
    
    override func resolvedModeTitleKeyForList() -> String? {
        currentMode().titleKey
    }
    
    private func getMaxSpeed() -> Double {
        let mode = currentMode()
        if mode == .total {
            if let analysis = getAnalysis() {
                let rawMaxSpeed = Double(analysis.maxSpeed)
                lastMaxSpeed = Int(rawMaxSpeed.rounded())
                return rawMaxSpeed
            } else {
                lastMaxSpeed = 0
                return 0
            }
        } else {
            return getLastSlopeMaxSpeed(mode: mode)
        }
    }
    
    private func getLastSlopeMaxSpeed(mode: MaxSpeedMode) -> Double {
        guard let lastSlope = getLastSlope(isUphill: mode == .lastUphill) else { return 0 }
        return lastSlope.maxSpeed
    }
    
    private func updateTitleAndIcon() {
        let mode = currentMode()
        let baseTitle = widgetType?.title ?? ""
        let modeTitle = localizedString(mode.titleKey)
        let format = localizedString("ltr_or_rtl_combine_via_colon")
        let fullTitle = String(format: format, baseTitle, modeTitle)
        setContentTitle(fullTitle)
        setIcon(mode.iconName)
        configureSimpleLayout()
    }
    
    private func currentMode() -> MaxSpeedMode {
        guard let pref = widgetState?.getMaxSpeedModePreference() else { return .total }
        return MaxSpeedMode(rawValue: Int(pref.get())) ?? .total
    }
}
