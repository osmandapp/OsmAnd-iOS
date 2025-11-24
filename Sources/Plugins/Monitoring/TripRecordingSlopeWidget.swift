//
//  TripRecordingSlopeWidget.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 22.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class TripRecordingSlopeWidget: BaseRecordingWidget {
    private var widgetState: TripRecordingSlopeWidgetState?
    private var cachedSlope: Int = -1
    private var forceUpdate = false
    
    init(customId: String?, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        super.init(type: .tripRecordingAverageSlope)
        self.widgetState = TripRecordingSlopeWidgetState(customId: customId, widgetType: .tripRecordingAverageSlope, widgetParams: widgetParams)
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
        let elevationSlope = getSlope()
        if forceUpdate || isUpdateNeeded() || cachedSlope != elevationSlope {
            cachedSlope = elevationSlope
            forceUpdate = false
            setText("\(elevationSlope)", subtext: "%")
        }
        
        updateTitleAndIcon()
        return true
    }
    
    override func getIconName() -> String? {
        currentMode().iconName
    }
    
    private func getSlope() -> Int {
        let lastSlope = getLastSlope(isUphill: widgetState?.getAverageSlopeModePreference().get() == Int32(AverageSlopeMode.lastUphill.rawValue))
        if let lastSlope {
            return Int(lastSlope.elevDiff / lastSlope.distance * 100.0)
        } else {
            return 0
        }
    }
    
    private func updateTitleAndIcon() {
        let mode = currentMode()
        let baseTitle = widgetType?.title ?? ""
        let modeTitle = localizedString(mode.titleKey)
        let format = localizedString("ltr_or_rtl_combine_via_colon")
        let fullTitle = String(format: format, baseTitle, modeTitle)
        setContentTitle(fullTitle)
        setIcon(mode.iconName)
    }
    
    private func currentMode() -> AverageSlopeMode {
        guard let pref = widgetState?.getAverageSlopeModePreference() else { return .lastUphill }
        return AverageSlopeMode(rawValue: Int(pref.get())) ?? .lastUphill
    }
}
