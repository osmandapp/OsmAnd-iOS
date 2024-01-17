//
//  TimeToNavigationPointWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 11.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OATimeToNavigationPointWidget)
@objcMembers
class TimeToNavigationPointWidget: OATextInfoWidget {
    private static let UPDATE_INTERVAL_SECONDS: Int64 = 30
    
    private let routingHelper: OARoutingHelper = OARoutingHelper.sharedInstance()!
    private var widgetState: TimeToNavigationPointWidgetState?
    private var arrivalTimeOtherwiseTimeToGoPref: OACommonBoolean
    
    private var cachedArrivalTimeOtherwiseTimeToGo: Bool
    private var cachedLeftSeconds: Int
    
    convenience init(widgetState: TimeToNavigationPointWidgetState, appMode: OAApplicationMode) {
        
        self.init(frame: .zero)
        
        self.widgetState = widgetState
        self.arrivalTimeOtherwiseTimeToGoPref = widgetState.getPreference()
        self.cachedArrivalTimeOtherwiseTimeToGo = arrivalTimeOtherwiseTimeToGoPref.get()
        self.cachedLeftSeconds = 0
        self.widgetType = widgetState.isIntermediate() ? WidgetType.timeToIntermediate : WidgetType.timeToDestination
        configurePrefs(withId: widgetState.customId, appMode: appMode)
        setText(nil, subtext: nil)
        updateIcons()
        updateContentTitle()
        onClickFunction = { [weak self] _ in
            self?.widgetState!.changeToNextState()
            _ = self?.updateInfo()
        }
    }
    
    override init(frame: CGRect) {
        self.widgetState = TimeToNavigationPointWidgetState(customId: "", intermediate: true)
        self.arrivalTimeOtherwiseTimeToGoPref = widgetState!.getPreference()
        self.cachedArrivalTimeOtherwiseTimeToGo = arrivalTimeOtherwiseTimeToGoPref.get()
        self.cachedLeftSeconds = 0
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func isIntermediate() -> Bool {
        return widgetState!.isIntermediate()
    }
    
    func getPreference() -> OACommonBoolean {
        return arrivalTimeOtherwiseTimeToGoPref
    }
    
    override func getWidgetState() -> OAWidgetState? {
        return widgetState
    }
    
    override func getSettingsData(_ appMode: OAApplicationMode) -> OATableDataModel? {
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")
        let settingRow = section.createNewRow()
        settingRow.cellType = OAValueTableViewCell.getIdentifier()
        settingRow.key = "value_pref"
        settingRow.title = widgetType!.title
        settingRow.descr = widgetType!.title
        settingRow.setObj(arrivalTimeOtherwiseTimeToGoPref, forKey: "pref")
        settingRow.setObj(widgetState!.getPrefValue(), forKey: "value")
        settingRow.setObj(getPossibleValues(), forKey: "possible_values")
        return data
    }
    
    private func getPossibleValues() -> [OATableRowData] {
        let isIntermediate = widgetState!.isIntermediate()
        var timeToGo = false
        var res = [OATableRowData]()
        for _ in 0..<2 {
            let pointState = TimeToNavigationPointState.getState(intermediate: isIntermediate, arrivalOtherwiseTimeToGo: !timeToGo)
            let row = OATableRowData()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.setObj(timeToGo ? "false" : "true", forKey: "value")
            row.title = pointState.title
            row.iconName = pointState.iconName
            res.append(row)
            timeToGo = true
        }
        return res
    }
    
    override func updateInfo() -> Bool {
        var leftSeconds = 0
        
        let timeModeUpdated = arrivalTimeOtherwiseTimeToGoPref.get() != cachedArrivalTimeOtherwiseTimeToGo
        if timeModeUpdated {
            cachedArrivalTimeOtherwiseTimeToGo = arrivalTimeOtherwiseTimeToGoPref.get()
            updateIcons()
            updateContentTitle()
        }
        
        if routingHelper.isRouteCalculated() {
            if widgetState!.isIntermediate() {
                leftSeconds = routingHelper.getLeftTimeNextIntermediate()
            } else {
                leftSeconds = routingHelper.getLeftTime()
            }
            let updateIntervalPassed = abs(leftSeconds - cachedLeftSeconds) > Int(Self.UPDATE_INTERVAL_SECONDS)
            if leftSeconds != 0 && (updateIntervalPassed || timeModeUpdated) {
                cachedLeftSeconds = leftSeconds
                if arrivalTimeOtherwiseTimeToGoPref.get() {
                    return updateArrivalTime(leftSeconds)
                } else {
                    return updateTimeToGo(leftSeconds)
                }
            }
        }
        
        if leftSeconds == 0 && cachedLeftSeconds != 0 {
            cachedLeftSeconds = 0
            setText(nil, subtext: nil)
            return true
        }
        return false
    }
    
    private func updateIcons() {
        let state = getCurrentState()
        setIcon(state.iconName)
    }
    
    private func updateContentTitle() {
        let title = getCurrentState().getTitle()
        setContentTitle(title)
    }
    
    private func updateArrivalTime(_ leftSeconds: Int) -> Bool {
        let toFindTime = Date().timeIntervalSince1970 + TimeInterval(leftSeconds)
        let dateFormatter = DateFormatter()
        let toFindDate = Date(timeIntervalSince1970: toFindTime)
        if !OAUtilities.is12HourTimeFormat() {
            dateFormatter.dateFormat = "HH:mm"
            setText(dateFormatter.string(from: toFindDate), subtext: nil)
        } else {
            dateFormatter.dateFormat = "h:mm"
            let timeStr = dateFormatter.string(from: toFindDate)
            dateFormatter.dateFormat = "a"
            let aStr = dateFormatter.string(from: toFindDate)
            setText(timeStr, subtext: aStr)
        }
        return true
    }
    
    private func updateTimeToGo(_ leftSeconds: Int) -> Bool {
        var hours: Int32 = 0, minutes: Int32 = 0, seconds: Int32 = 0
        OAUtilities.getHMS(TimeInterval(leftSeconds), hours: &hours, minutes: &minutes, seconds: &seconds)
        let timeStr = String(format: "%d:%02d", hours, minutes)
        setText(timeStr, subtext: nil)
        return true
    }
    
    private func getCurrentState() -> TimeToNavigationPointState {
        return TimeToNavigationPointState.getState(intermediate: widgetState!.isIntermediate(), arrivalOtherwiseTimeToGo: arrivalTimeOtherwiseTimeToGoPref.get())
    }
}

