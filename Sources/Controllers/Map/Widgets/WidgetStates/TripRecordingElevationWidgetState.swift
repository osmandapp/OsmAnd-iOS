//
//  TripRecordingElevationWidgetState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 26.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objc enum TripRecordingElevationMode: Int, CaseIterable {
    case total
    case last
    
    func titleKey(isUphill: Bool) -> String {
        switch self {
        case .total:
            return "shared_string_total"
        case .last:
            return isUphill ? "shared_string_last_uphill" : "shared_string_last_downhill"
        }
    }
    
    func iconName(isUphill: Bool) -> String {
        switch self {
        case .total:
            return isUphill ? "widget_track_recording_uphill" : "widget_track_recording_downhill"
        case .last:
            return isUphill ? "widget_track_recording_last_uphill" : "widget_track_recording_last_downhill"
        }
    }
    
    func next() -> TripRecordingElevationMode {
        let nextRaw = (rawValue + 1) % Self.allCases.count
        return TripRecordingElevationMode(rawValue: nextRaw) ?? self
    }
}

@objcMembers
final class TripRecordingElevationWidgetState: OAWidgetState {
    static let prefUphillWidgetModeId = "uphill_widget_mode"
    
    private let widgetType: WidgetType
    private let elevationModePreference: OACommonInteger
    private let isUphillType: Bool
    
    init(isUphillType: Bool, customId: String?, widgetType: WidgetType, widgetParams: [String: Any]? = nil) {
        self.widgetType = widgetType
        self.isUphillType = isUphillType
        self.elevationModePreference = Self.registerPreference(customId: customId, widgetParams: widgetParams)
    }
    
    override func getMenuTitle() -> String {
        widgetType.title
    }
    
    override func getSettingsIconId(_ nightMode: Bool) -> String? {
        widgetType.iconName
    }
    
    override func changeToNextState() {
        elevationModePreference.set(Int32(getElevationMode().next().rawValue))
    }
    
    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerPreference(customId: customId).set(elevationModePreference.get(appMode), mode: appMode)
    }
    
    func getElevationModePreference() -> OACommonInteger {
        elevationModePreference
    }
    
    func getModeTitleKey() -> String {
        getElevationMode().titleKey(isUphill: isUphillType)
    }
    
    func getModeIconName() -> String {
        getElevationMode().iconName(isUphill: isUphillType)
    }
    
    private static func registerPreference(customId: String?, widgetParams: [String: Any]? = nil) -> OACommonInteger {
        var prefId = Self.prefUphillWidgetModeId
        if let customId, !customId.isEmpty {
            prefId += customId
        }
        
        let pref = OAAppSettings.sharedManager().registerIntPreference(prefId, defValue: Int32(TripRecordingElevationMode.total.rawValue)).makeProfile()
        if let string = widgetParams?[Self.prefUphillWidgetModeId] as? String, let intVal = Int32(string) {
            pref.set(intVal)
        }
        
        return pref
    }
    
    private func getElevationMode() -> TripRecordingElevationMode {
        TripRecordingElevationMode(rawValue: Int(elevationModePreference.get())) ?? .total
    }
}
