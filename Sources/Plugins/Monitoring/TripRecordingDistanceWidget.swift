//
//  TripRecordingDistanceWidget.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 25.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class TripRecordingDistanceWidget: BaseRecordingWidget {
    private let savingTrackHelper = OASavingTrackHelper.sharedInstance()
    private let blinkDelay: TimeInterval = 0.5
    
    private var widgetState: TripRecordingDistanceWidgetState?
    private var cachedLastUpdateTime: Int64 = 0
    
    init(customId: String?, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        super.init(type: .tripRecordingDistance)
        self.widgetState = TripRecordingDistanceWidgetState(customId: customId, widgetType: .tripRecordingDistance, widgetParams: widgetParams)
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        updateInfo()
        onClickFunction = { [weak self] _ in
            guard let self, let plugin = self.getMonitoringPlugin() else { return }
            plugin.showTripRecordingDialog()
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
        guard let plugin = getMonitoringPlugin() else { return true }
        guard let savingTrackHelper else { return true }
        if plugin.saving {
            setText(localizedString("shared_string_save"), subtext: nil)
            setIcon("widget_monitoring_rec_big")
            return true
        }
        
        let recordingDistanceMode = currentMode()
        if recordingDistanceMode == .totalDistance {
            var lastUpdateTime = cachedLastUpdateTime
            let globalRecording = OAAppSettings.sharedManager().mapSettingTrackRecording
            let recording = savingTrackHelper.getIsRecording()
            let liveMonitoring = plugin.isLiveMonitoringEnabled()
            let distance = savingTrackHelper.distance
            setDistanceText(distance)
            setRecordingIcons(globalRecording: globalRecording, liveMonitoring: liveMonitoring, recording: recording)
            if distance > 0 {
                lastUpdateTime = Int64(savingTrackHelper.lastTimeUpdated)
            }
            
            if lastUpdateTime != cachedLastUpdateTime && (globalRecording || recording) {
                cachedLastUpdateTime = lastUpdateTime
                setRecordingIcons(globalRecording: false, liveMonitoring: liveMonitoring, recording: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + blinkDelay) { [weak self] in
                    guard let self else { return }
                    self.setRecordingIcons(globalRecording: globalRecording,
                                           liveMonitoring: liveMonitoring,
                                           recording: !globalRecording)
                }
            }
        } else {
            updateLastSlopeDistance(mode: recordingDistanceMode)
            setIcon(recordingDistanceMode.iconName)
        }
        
        updateTitleAndIcon()
        return true
    }
    
    override func getSettingsData(_ appMode: OAApplicationMode, widgetConfigurationParams: [String: Any]?, isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()
        guard let pref = widgetState?.getDistanceModePreference() else { return data }
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")
        let modeRow = section.createNewRow()
        modeRow.cellType = OAButtonTableViewCell.reuseIdentifier
        modeRow.key = "recording_widget_mode_key"
        modeRow.title = localizedString("shared_string_mode")
        modeRow.setObj(pref, forKey: "pref")
        var currentRaw = TripRecordingDistanceMode.totalDistance.rawValue
        if isCreate, let widgetConfigurationParams, let str = widgetConfigurationParams[pref.key] as? String, let v = Int(str) {
            currentRaw = v
        } else if !isCreate {
            currentRaw = Int(pref.get(appMode))
        }
        
        let currentMode = TripRecordingDistanceMode(rawValue: currentRaw) ?? .totalDistance
        modeRow.setObj(localizedString(currentMode.titleKey), forKey: "value")
        let possibleValues: [OATableRowData] = [TripRecordingDistanceMode.totalDistance, .lastDownhill, .lastUphill].map { mode in
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
    
    private func updateLastSlopeDistance(mode: TripRecordingDistanceMode) {
        if let lastSlope = getLastSlope(isUphill: mode == .lastUphill) {
            setDistanceText(Float(lastSlope.distance))
        } else {
            setDistanceText(0)
        }
    }
    
    private func setDistanceText(_ distance: Float) {
        guard distance > 0 else {
            setText(localizedString("monitoring_control_start"), subtext: nil)
            return
        }
        
        let parts = OAOsmAndFormatter.getFormattedDistance(distance).components(separatedBy: " ")
        setText(parts.first, subtext: parts.dropFirst().last)
    }
    
    private func setRecordingIcons(globalRecording: Bool, liveMonitoring: Bool, recording: Bool) {
        let iconName: String
        if globalRecording {
            iconName = liveMonitoring ? "widget_live_monitoring_rec_big" : "widget_monitoring_rec_big"
        } else if recording {
            iconName = liveMonitoring ? "widget_live_monitoring_rec_small" : "widget_monitoring_rec_small"
        } else {
            iconName = "widget_monitoring_rec_inactive"
        }
        
        setIcon(iconName)
    }
    
    private func getMonitoringPlugin() -> OAMonitoringPlugin? {
        OAPluginsHelper.getPlugin(OAMonitoringPlugin.self) as? OAMonitoringPlugin
    }
    
    private func updateTitleAndIcon() {
        let mode = currentMode()
        let baseTitle = widgetType?.title ?? ""
        let modeTitle = localizedString(mode.titleKey)
        let format = localizedString("ltr_or_rtl_combine_via_colon")
        let fullTitle = String(format: format, baseTitle, modeTitle)
        setContentTitle(fullTitle)
        if mode != .totalDistance {
            setIcon(mode.iconName)
        }
        
        configureSimpleLayout()
    }
    
    private func currentMode() -> TripRecordingDistanceMode {
        guard let pref = widgetState?.getDistanceModePreference() else { return .totalDistance }
        return TripRecordingDistanceMode(rawValue: Int(pref.get())) ?? .totalDistance
    }
}
