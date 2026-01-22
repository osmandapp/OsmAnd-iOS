//
//  TripRecordingDistanceWidgetState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 25.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objc enum TripRecordingDistanceMode: Int, CaseIterable {
    case totalDistance
    case lastDownhill
    case lastUphill
    
    var titleKey: String {
        switch self {
        case .totalDistance:
            return "total_distance"
        case .lastDownhill:
            return "shared_string_last_downhill"
        case .lastUphill:
            return "shared_string_last_uphill"
        }
    }
    
    var iconName: String {
        switch self {
        case .totalDistance:
            return "widget_trip_recording_distance"
        case .lastDownhill:
            return "widget_trip_recording_distance_last_downhill"
        case .lastUphill:
            return "widget_trip_recording_distance_last_uphill"
        }
    }
    
    func next() -> TripRecordingDistanceMode {
        let nextRaw = (rawValue + 1) % Self.allCases.count
        return TripRecordingDistanceMode(rawValue: nextRaw) ?? self
    }
}

@objcMembers
final class TripRecordingDistanceWidgetState: OAWidgetState {
    static let prefDistanceModeId = "trip_recording_distance_widget_mode"
    
    private let widgetType: WidgetType
    private let distanceModePreference: OACommonTripRecordingDistanceMode
    
    init(customId: String?, widgetType: WidgetType, widgetParams: [String: Any]? = nil) {
        self.widgetType = widgetType
        self.distanceModePreference = Self.registerPreference(customId: customId, widgetParams: widgetParams)
    }
    
    override func getMenuTitle() -> String {
        widgetType.title
    }
    
    override func getSettingsIconId(_ nightMode: Bool) -> String? {
        widgetType.iconName
    }
    
    override func changeToNextState() {
        distanceModePreference.set(getDistanceMode().next().rawValue)
    }
    
    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerPreference(customId: customId).set(distanceModePreference.get(appMode), mode: appMode)
    }
    
    func getDistanceModePreference() -> OACommonTripRecordingDistanceMode {
        distanceModePreference
    }
    
    private static func registerPreference(customId: String?, widgetParams: [String: Any]? = nil) -> OACommonTripRecordingDistanceMode {
        var prefId = Self.prefDistanceModeId
        if let customId, !customId.isEmpty {
            prefId += customId
        }
        
        let pref = OAAppSettings.sharedManager().registerTripRecordingDistanceModePreference(prefId, defValue: TripRecordingDistanceMode.totalDistance.rawValue).makeProfile()
        if let string = widgetParams?[Self.prefDistanceModeId] as? String, let intVal = Int(string) {
            pref.set(intVal)
        }
        
        return pref
    }
    
    private func getDistanceMode() -> TripRecordingDistanceMode {
        TripRecordingDistanceMode(rawValue: Int(distanceModePreference.get())) ?? .totalDistance
    }
}
