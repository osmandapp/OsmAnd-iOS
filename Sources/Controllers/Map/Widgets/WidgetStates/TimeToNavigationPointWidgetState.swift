//
//  TimeToNavigationPointWidgetState.swift
//  OsmAnd Maps
//
//  Created by Paul on 03.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OATimeToNavigationPointWidgetState)
@objcMembers
class TimeToNavigationPointWidgetState: OAWidgetState {
    
    private let intermediate: Bool
    private let arrivalTimeOrTimeToGo: OACommonBoolean
    
    init(customId: String?, intermediate: Bool) {
        self.intermediate = intermediate
        self.arrivalTimeOrTimeToGo = TimeToNavigationPointWidgetState.registerTimeTypePref(customId: customId, intermediate: intermediate)
    }
    
    func isIntermediate() -> Bool {
        return intermediate
    }
    
    func getPreference() -> OACommonBoolean {
        return arrivalTimeOrTimeToGo
    }
    
    override func getMenuTitle() -> String {
        return TimeToNavigationPointState.getState(intermediate: intermediate, arrivalOtherwiseTimeToGo: arrivalTimeOrTimeToGo.get()).getTitle()
    }
    
    func getPrefValue() -> String {
        TimeToNavigationPointState.getState(intermediate: intermediate, arrivalOtherwiseTimeToGo: arrivalTimeOrTimeToGo.get()).title
    }
    
    override func getSettingsIconId(_ nightMode: Bool) -> String {
        return TimeToNavigationPointState.getState(intermediate: intermediate, arrivalOtherwiseTimeToGo: arrivalTimeOrTimeToGo.get()).getIconName(nightMode: nightMode)
    }
    
    override func changeToNextState() {
        arrivalTimeOrTimeToGo.set(!arrivalTimeOrTimeToGo.get())
    }
    
    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        TimeToNavigationPointWidgetState.registerTimeTypePref(customId: customId, intermediate: intermediate).set(arrivalTimeOrTimeToGo.get(appMode), mode: appMode)
    }
    
    private static func registerTimeTypePref(customId: String?, intermediate: Bool) -> OACommonBoolean {
        var prefId = intermediate ? "show_arrival_time" : "show_intermediate_arrival_time"
        if let customId, !customId.isEmpty {
            prefId += customId
        }
        return OAAppSettings.sharedManager().registerBooleanPreference(prefId, defValue: true)
    }
}

@objc(OATimeToNavigationPointState)
@objcMembers
class TimeToNavigationPointState: NSObject {

    static let intermediateTimeToGo = TimeToNavigationPointState(
        title: localizedString("map_widget_time"),
        dayIconName: "widget_intermediate_time_to_go_day",
        nightIconName: "widget_intermediate_time_to_go_night",
        intermediate: true
    )

    static let intermediateArrivalTime = TimeToNavigationPointState(
        title: localizedString("access_arrival_time"),
        dayIconName: "widget_intermediate_time_day",
        nightIconName: "widget_intermediate_time_night",
        intermediate: true
    )

    static let destinationTimeToGo = TimeToNavigationPointState(
        title: localizedString("map_widget_time"),
        dayIconName: "widget_destination_time_to_go_day",
        nightIconName: "widget_destination_time_to_go_night",
        intermediate: false
    )

    static let destinationArrivalTime = TimeToNavigationPointState(
        title: localizedString("access_arrival_time"),
        dayIconName: "widget_time_to_distance_day",
        nightIconName: "widget_time_to_distance_night",
        intermediate: false
    )

    let title: String
    let dayIconName: String
    let nightIconName: String
    let intermediate: Bool

    init(title: String, dayIconName: String, nightIconName: String, intermediate: Bool) {
        self.title = title
        self.dayIconName = dayIconName
        self.nightIconName = nightIconName
        self.intermediate = intermediate
    }

    func getTitle() -> String {
        intermediate
            ? localizedString("map_widget_time_to_intermediate")
            : localizedString("map_widget_time_to_destination")
    }

    func getIconName(nightMode: Bool) -> String {
        nightMode ? nightIconName : dayIconName
    }

    static func getState(intermediate: Bool, arrivalOtherwiseTimeToGo: Bool) -> TimeToNavigationPointState {
        if intermediate {
            return arrivalOtherwiseTimeToGo ? intermediateArrivalTime : intermediateTimeToGo
        } else {
            return arrivalOtherwiseTimeToGo ? destinationArrivalTime : destinationTimeToGo
        }
    }

}

