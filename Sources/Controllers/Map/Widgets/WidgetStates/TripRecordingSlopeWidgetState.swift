//
//  TripRecordingSlopeWidgetState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 23.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objc enum AverageSlopeMode: Int, CaseIterable {
    case lastDownhill
    case lastUphill
    
    var titleKey: String {
        switch self {
        case .lastDownhill:
            return "shared_string_last_downhill"
        case .lastUphill:
            return "shared_string_last_uphill"
        }
    }
    
    var iconName: String {
        switch self {
        case .lastDownhill:
            return "widget_track_recording_average_slope_downhill"
        case .lastUphill:
            return "widget_track_recording_average_slope_uphill"
        }
    }
    
    func next() -> AverageSlopeMode {
        let nextRaw = (rawValue + 1) % Self.allCases.count
        return AverageSlopeMode(rawValue: nextRaw) ?? self
    }
}

@objcMembers
final class TripRecordingSlopeWidgetState: OAWidgetState {
    static let prefAverageSlopeModeId = "average_slope_widget_mode"
    
    private let widgetType: WidgetType
    private let averageSlopeModePreference: OACommonTripRecordingAverageSlopeMode
    
    init(customId: String?, widgetType: WidgetType, widgetParams: [String: Any]? = nil) {
        self.widgetType = widgetType
        self.averageSlopeModePreference = Self.registerPreference(customId: customId, widgetParams: widgetParams)
    }
    
    override func getMenuTitle() -> String {
        widgetType.title
    }
    
    override func getSettingsIconId(_ nightMode: Bool) -> String? {
        widgetType.iconName
    }
    
    override func changeToNextState() {
        averageSlopeModePreference.set(getAverageSlopeMode().next().rawValue)
    }
    
    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerPreference(customId: customId).set(averageSlopeModePreference.get(appMode), mode: appMode)
    }
    
    func getAverageSlopeModePreference() -> OACommonTripRecordingAverageSlopeMode {
        averageSlopeModePreference
    }
    
    private static func registerPreference(customId: String?, widgetParams: [String: Any]? = nil) -> OACommonTripRecordingAverageSlopeMode {
        var prefId = Self.prefAverageSlopeModeId
        if let customId, !customId.isEmpty {
            prefId += customId
        }
        
        let pref = OAAppSettings.sharedManager().registerAverageSlopeModePreference(prefId, defValue: AverageSlopeMode.lastUphill.rawValue).makeProfile()
        if let string = widgetParams?[Self.prefAverageSlopeModeId] as? String, let intVal = Int32(string) {
            pref.set(Int(intVal))
        }
        
        return pref
    }
    
    private func getAverageSlopeMode() -> AverageSlopeMode {
        AverageSlopeMode(rawValue: Int(averageSlopeModePreference.get())) ?? .lastUphill
    }
}
