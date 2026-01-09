//
//  TripRecordingMovingTimeWidget.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 07.01.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class TripRecordingMovingTimeWidget: BaseRecordingWidget {
    private var widgetState: TripRecordingMovingTimeWidgetState?
    private var cachedTimeMoving: Int64 = -1
    private var forceUpdate = false
    
    init(customId: String?, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        super.init(type: .tripRecordingMovingTime)
        self.widgetState = TripRecordingMovingTimeWidgetState(customId: customId, widgetType: .tripRecordingMovingTime, widgetParams: widgetParams)
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
        let timeMoving = getTimeMoving()
        if forceUpdate || isUpdateNeeded() || cachedTimeMoving != timeMoving {
            cachedTimeMoving = timeMoving
            forceUpdate = false
            let formatted = OAOsmAndFormatter.getFormattedDurationShort(Double(timeMoving) / 1000, fullForm: false)
            let isHourOrMore = timeMoving >= 60 * 60 * 1000
            let unitKey = isHourOrMore ? "int_hour" : "shared_string_minute_lowercase"
            setText(formatted, subtext: localizedString(unitKey))
        }
        
        updateTitleAndIcon()
        return true
    }
    
    override func getSettingsData(_ appMode: OAApplicationMode, widgetConfigurationParams: [String: Any]?, isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()
        guard let pref = widgetState?.getMovingTimeModePreference() else { return data }
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")
        let modeRow = section.createNewRow()
        modeRow.cellType = OAButtonTableViewCell.reuseIdentifier
        modeRow.key = "recording_widget_mode_key"
        modeRow.title = localizedString("shared_string_mode")
        modeRow.setObj(pref, forKey: "pref")
        var currentRaw = TripRecordingMovingTimeMode.total.rawValue
        if isCreate, let widgetConfigurationParams, let str = widgetConfigurationParams[pref.key] as? String, let v = Int(str) {
            currentRaw = v
        } else if !isCreate {
            currentRaw = Int(pref.get(appMode))
        }
        
        let currentMode = TripRecordingMovingTimeMode(rawValue: currentRaw) ?? .total
        modeRow.setObj(localizedString(currentMode.titleKey), forKey: "value")
        let possibleValues: [OATableRowData] = [TripRecordingMovingTimeMode.total, .lastDownhill, .lastUphill].map { mode in
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
    
    override func resolvedModeTitleKeyForList() -> String? {
        currentMode().titleKey
    }
    
    private func getTimeMoving() -> Int64 {
        let mode = currentMode()
        if mode == .total {
            return getTotalMovingTime()
        } else {
            return getLastSlopeMovingTime(mode: mode)
        }
    }
    
    private func getTotalMovingTime() -> Int64 {
        guard let currentTrack = OASavingTrackHelper.sharedInstance().currentTrack else { return 0 }
        let joinSegments = OAAppSettings.sharedManager().currentTrackIsJoinSegments.get()
        let tracks = (currentTrack.tracks as? [Track]) ?? []
        let firstIsGeneral = tracks.first?.generalTrack ?? false
        let withoutGaps = !joinSegments && (tracks.isEmpty || firstIsGeneral)
        let analysis = currentTrack.getAnalysis(fileTimestamp: 0)
        return withoutGaps ? analysis.timeMovingWithoutGaps : analysis.timeMoving
    }
    
    private func getLastSlopeMovingTime(mode: TripRecordingMovingTimeMode) -> Int64 {
        guard let lastSlope = getLastSlope(isUphill: mode == .lastUphill) else { return 0 }
        return Int64(lastSlope.movingTime)
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
    
    private func currentMode() -> TripRecordingMovingTimeMode {
        guard let pref = widgetState?.getMovingTimeModePreference() else { return .total }
        return TripRecordingMovingTimeMode(rawValue: Int(pref.get())) ?? .total
    }
}
