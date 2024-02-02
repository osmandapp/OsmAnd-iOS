//
//  MapMarkerSideWidgetState.swift
//  OsmAnd Maps
//
//  Created by Paul on 02.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAMapMarkerSideWidgetState)
@objcMembers
class MapMarkerSideWidgetState: OAWidgetState {
    static let availableIntervals: [Int: String] = getAvailableIntervals()
    
    let settings = OAAppSettings.sharedManager()!
    let mapMarkerModePref: OACommonString
    let markerClickBehaviourPref: OACommonString
    let averageSpeedIntervalPref: OACommonLong
    let firstMarker: Bool
    
    var customId: String?
    
    init(customId: String?, firstMarker: Bool) {
        self.customId = customId
        self.firstMarker = firstMarker
        self.mapMarkerModePref = MapMarkerSideWidgetState.registerModePref(customId, settings: settings, firstMarker: firstMarker)
        self.markerClickBehaviourPref = MapMarkerSideWidgetState.registerMarkerClickBehaviourPref(customId, settings: settings, firstMarker: firstMarker)
        self.averageSpeedIntervalPref = MapMarkerSideWidgetState.registerAverageSpeedIntervalPref(customId, settings: settings, firstMarker: firstMarker)
    }
    
    private static func registerModePref(_ customId: String?, settings: OAAppSettings, firstMarker: Bool) -> OACommonString {
        var prefId = firstMarker ? "first_map_marker_mode" : "second_map_marker_mode"
        if let customId, !customId.isEmpty {
            prefId += customId
        }
        return settings.registerStringPreference(prefId, defValue: SideMarkerMode.distance.name)
    }
    
    private static func registerAverageSpeedIntervalPref(_ customId: String?, settings: OAAppSettings, firstMarker: Bool) -> OACommonLong {
        var prefId = firstMarker ? "first_map_marker_interval" : "second_map_marker_interval"
        if let customId, !customId.isEmpty {
            prefId += customId
        }
        return settings.registerLongPreference(prefId, defValue: OAAverageSpeedComputer.default_INTERVAL_MILLIS())
    }
    
    private static func registerMarkerClickBehaviourPref(_ customId: String?, settings: OAAppSettings, firstMarker: Bool) -> OACommonString {
        var prefId = firstMarker ? "first_map_marker_click_behaviour" : "second_map_marker_click_behaviour"
        if let customId, !customId.isEmpty {
            prefId += customId
        }
        return settings.registerStringPreference(prefId, defValue: MarkerClickBehaviour.switchMode.name)
    }
    
    override func getMenuTitle() -> String! {
        let widgetType = firstMarker ? WidgetType.sideMarker1 : WidgetType.sideMarker2
        let title = widgetType.title
        let subtitle = SideMarkerMode.markerModeByName(mapMarkerModePref.get())!.title
        return String(format: localizedString("ltr_or_rtl_combine_via_colon"), title, subtitle)
    }
    
    override func getSettingsIconId(_ nightMode: Bool) -> String! {
        SideMarkerMode.markerModeByName(mapMarkerModePref.get())!.iconName
    }
    
    override func changeToNextState() {
        mapMarkerModePref.set(SideMarkerMode.markerModeByName(mapMarkerModePref.get())!.next().name)
    }
    
    override func copyPrefs(_ appMode: OAApplicationMode!, customId: String!) {
        let _ = MapMarkerSideWidgetState.registerModePref(customId, settings: settings, firstMarker: firstMarker)
        let _ = MapMarkerSideWidgetState.registerAverageSpeedIntervalPref(customId, settings: settings, firstMarker: firstMarker)
    }
    
    func isFirstMarker() -> Bool {
        return firstMarker
    }

    private static func getAvailableIntervals() -> [Int: String] {
        var intervals = [Int: String]()
        for mInterval in OAAverageSpeedComputer.measured_INTERVALS() {
            let interval = mInterval.intValue
            let seconds = interval < 60 * 1000
            let timeInterval = seconds
                ? String(interval / 1000)
                : String(interval / 1000 / 60)
            let timeUnit = interval < 60 * 1000
                ? localizedString("shared_string_sec")
                : localizedString("int_min")
            let formattedInterval = String(format: localizedString("ltr_or_rtl_combine_via_space"), timeInterval, timeUnit)
            intervals[interval] = formattedInterval
        }
        return intervals
    }

}

@objc(OASideMarkerMode)
@objcMembers
class SideMarkerMode: NSObject {

    static let distance = SideMarkerMode(ordinal: 0, name: "DISTANCE", title: localizedString("shared_string_distance"), iconName: "widget_marker", foregroundIconName: "widget_marker_eta_triangle")
    static let estimatedArrivalTime = SideMarkerMode(ordinal: 1, name: "ESTIMATED_ARRIVAL_TIME", title: localizedString("side_marker_eta"), iconName: "widget_marker_eta", foregroundIconName: "widget_marker_eta_triangle")

    static let values = [SideMarkerMode.distance, SideMarkerMode.estimatedArrivalTime]
    
    let ordinal: Int
    let name: String
    let title: String
    let iconName: String
    let foregroundIconName: String
    
    private init(ordinal: Int, name: String, title: String, iconName: String, foregroundIconName: String) {
        self.ordinal = ordinal
        self.name = name
        self.title = title
        self.iconName = iconName
        self.foregroundIconName = foregroundIconName
    }

    func next() -> SideMarkerMode {
        let nextItemIndex = (ordinal + 1) % SideMarkerMode.values.count
        return SideMarkerMode.values[nextItemIndex]
    }
    
    static func markerModeByName(_ name: String) -> SideMarkerMode? {
        SideMarkerMode.values.filter {
            $0.name == name
        }.first
    }
}

@objc(OAMarkerClickBehaviour)
@objcMembers
class MarkerClickBehaviour: NSObject {
    
    static let switchMode = MarkerClickBehaviour(name: "SWITCH_MODE", title: localizedString("shared_string_switch_mode"))
    static let goToMarkerLocation = MarkerClickBehaviour(name: "GO_TO_MARKER_LOCATION",title: localizedString("go_to_marker_location"))
    
    static let values = [MarkerClickBehaviour.switchMode, MarkerClickBehaviour.goToMarkerLocation]
    
    let name: String
    let title: String
    
    private init(name: String, title: String) {
        self.name = name
        self.title = title
    }
    
    static func behaviorByName(_ name: String) -> MarkerClickBehaviour? {
        MarkerClickBehaviour.values.filter { $0.name == name }.first
    }
}
