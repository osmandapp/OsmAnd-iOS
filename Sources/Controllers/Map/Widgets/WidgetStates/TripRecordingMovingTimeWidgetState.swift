//
//  TripRecordingMovingTimeWidgetState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 07.01.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objc enum TripRecordingMovingTimeMode: Int, CaseIterable {
    case total
    case lastDownhill
    case lastUphill
    
    var titleKey: String {
        switch self {
        case .total:
            return "shared_string_total"
        case .lastDownhill:
            return "shared_string_last_downhill"
        case .lastUphill:
            return "shared_string_last_uphill"
        }
    }
    
    var iconName: String {
        switch self {
        case .total:
            return "widget_track_recording_moving_time"
        case .lastDownhill:
            return "widget_track_recording_moving_time_downhill"
        case .lastUphill:
            return "widget_track_recording_moving_time_uphill"
        }
    }
    
    func next() -> TripRecordingMovingTimeMode {
        let nextRaw = (rawValue + 1) % Self.allCases.count
        return TripRecordingMovingTimeMode(rawValue: nextRaw) ?? self
    }
}

@objcMembers
final class TripRecordingMovingTimeWidgetState: OAWidgetState {
    static let prefMovingTimeModeId = "trip_recording_moving_time_widget_mode"
    
    private let widgetType: WidgetType
    private let movingTimeModePreference: OACommonTripRecordingMovingTimeMode
    
    init(customId: String?, widgetType: WidgetType, widgetParams: [String: Any]? = nil) {
        self.widgetType = widgetType
        self.movingTimeModePreference = Self.registerPreference(customId: customId, widgetParams: widgetParams)
    }
    
    override func getMenuTitle() -> String {
        widgetType.title
    }
    
    override func getSettingsIconId(_ nightMode: Bool) -> String? {
        widgetType.iconName
    }
    
    override func changeToNextState() {
        movingTimeModePreference.set(getMovingTimeMode().next().rawValue)
    }
    
    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerPreference(customId: customId).set(movingTimeModePreference.get(appMode), mode: appMode)
    }
    
    func getMovingTimeModePreference() -> OACommonTripRecordingMovingTimeMode {
        movingTimeModePreference
    }
    
    private static func registerPreference(customId: String?, widgetParams: [String: Any]? = nil) -> OACommonTripRecordingMovingTimeMode {
        var prefId = Self.prefMovingTimeModeId
        if let customId, !customId.isEmpty {
            prefId += customId
        }
        
        let pref = OAAppSettings.sharedManager().registerTripRecordingMovingTimeModePreference(prefId, defValue: TripRecordingMovingTimeMode.total.rawValue).makeProfile()
        if let string = widgetParams?[Self.prefMovingTimeModeId] as? String, let intVal = Int(string) {
            pref.set(intVal)
        }
        
        return pref
    }
    
    private func getMovingTimeMode() -> TripRecordingMovingTimeMode {
        TripRecordingMovingTimeMode(rawValue: Int(movingTimeModePreference.get())) ?? .total
    }
}
