//
//  TripRecordingMaxSpeedWidgetState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 24.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objc enum MaxSpeedMode: Int, CaseIterable {
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
            return "widget_track_recording_max_speed"
        case .lastDownhill:
            return "widget_track_recording_max_speed_last_downhill"
        case .lastUphill:
            return "widget_track_recording_max_speed_last_uphill"
        }
    }
    
    func next() -> MaxSpeedMode {
        let nextRaw = (rawValue + 1) % Self.allCases.count
        return MaxSpeedMode(rawValue: nextRaw) ?? self
    }
}

@objcMembers
final class TripRecordingMaxSpeedWidgetState: OAWidgetState {
    static let prefMaxSpeedModeId = "max_speed_widget_mode"
    
    private let widgetType: WidgetType
    private let maxSpeedModePreference: OACommonTripRecordingMaxSpeedMode
    
    init(customId: String?, widgetType: WidgetType, widgetParams: [String: Any]? = nil) {
        self.widgetType = widgetType
        self.maxSpeedModePreference = Self.registerPreference(customId: customId, widgetParams: widgetParams)
    }
    
    override func getMenuTitle() -> String {
        widgetType.title
    }
    
    override func getSettingsIconId(_ nightMode: Bool) -> String? {
        widgetType.iconName
    }
    
    override func changeToNextState() {
        maxSpeedModePreference.set(getMaxSpeedMode().next().rawValue)
    }
    
    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerPreference(customId: customId).set(maxSpeedModePreference.get(appMode), mode: appMode)
    }
    
    func getMaxSpeedModePreference() -> OACommonTripRecordingMaxSpeedMode {
        maxSpeedModePreference
    }
    
    private static func registerPreference(customId: String?, widgetParams: [String: Any]? = nil) -> OACommonTripRecordingMaxSpeedMode {
        var prefId = Self.prefMaxSpeedModeId
        if let customId, !customId.isEmpty {
            prefId += customId
        }
        
        let pref = OAAppSettings.sharedManager().registerMaxSpeedModePreference(prefId, defValue: MaxSpeedMode.total.rawValue).makeProfile()
        if let string = widgetParams?[Self.prefMaxSpeedModeId] as? String, let intVal = Int32(string) {
            pref.set(Int(intVal))
        }
        
        return pref
    }
    
    private func getMaxSpeedMode() -> MaxSpeedMode {
        MaxSpeedMode(rawValue: Int(maxSpeedModePreference.get())) ?? .total
    }
}
