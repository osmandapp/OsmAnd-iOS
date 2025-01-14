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
    
    var customId: String?
    
    init(customId: String?, intermediate: Bool, widgetParams: ([String: Any])?) {
        self.customId = customId
        self.intermediate = intermediate
        self.arrivalTimeOrTimeToGo = TimeToNavigationPointWidgetState.registerTimeTypePref(customId: customId, intermediate: intermediate, widgetParams: widgetParams)
    }
    
    func isIntermediate() -> Bool {
        intermediate
    }
    
    func getPreference() -> OACommonBoolean {
        arrivalTimeOrTimeToGo
    }
    
    override func getMenuTitle() -> String {
        TimeToNavigationPointState.getState(intermediate: intermediate, arrivalOtherwiseTimeToGo: arrivalTimeOrTimeToGo.get()).getTitle()
    }
    
    override func getWidgetTitle() -> String? {
        TimeToNavigationPointState.getState(intermediate: intermediate, arrivalOtherwiseTimeToGo: arrivalTimeOrTimeToGo.get()).getWidgetTitle()
    }
    
    func getPrefValue(widgetConfigurationParams: [String: Any]?,
                      isCreate: Bool) -> String {
        var currentValue = arrivalTimeOrTimeToGo.defValue
        if let widgetConfigurationParams,
           let key = widgetConfigurationParams.keys.first(where: { $0.hasPrefix("showArrivalTime") || $0.hasPrefix("showIntermediateArrivalTime") }),
           let value = widgetConfigurationParams[key] as? String,
           let widgetValue = Bool(value) {
            currentValue = widgetValue
        } else if !isCreate {
            currentValue = arrivalTimeOrTimeToGo.get()
        }
        
        return TimeToNavigationPointState.getState(intermediate: intermediate, arrivalOtherwiseTimeToGo: currentValue).title
    }
    
    override func getSettingsIconId(_ nightMode: Bool) -> String {
        TimeToNavigationPointState.getState(intermediate: intermediate, arrivalOtherwiseTimeToGo: arrivalTimeOrTimeToGo.get()).iconName
    }
    
    override func changeToNextState() {
        arrivalTimeOrTimeToGo.set(!arrivalTimeOrTimeToGo.get())
    }
    
    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        TimeToNavigationPointWidgetState.registerTimeTypePref(customId: customId, intermediate: intermediate).set(arrivalTimeOrTimeToGo.get(appMode), mode: appMode)
    }
    
    private static func registerTimeTypePref(customId: String?,
                                             intermediate: Bool,
                                             widgetParams: ([String: Any])? = nil) -> OACommonBoolean {
        var prefId = intermediate ? "show_arrival_time" : "show_intermediate_arrival_time"
        if let customId, !customId.isEmpty {
            prefId += customId
        }
        
        let preference = OAAppSettings.sharedManager().registerBooleanPreference(prefId, defValue: true)!
        
        if let string = widgetParams?["showArrivalTime"] as? String ?? widgetParams?["showIntermediateArrivalTime"] as? String, let widgetValue = Bool(string) {
            preference.set(widgetValue)
        }
        return preference
    }
}

@objc(OATimeToNavigationPointState)
@objcMembers
class TimeToNavigationPointState: NSObject {
    
    static let intermediateTimeToGo = TimeToNavigationPointState(
        title: localizedString("map_widget_time"),
        iconName: "widget_intermediate_time_to_go",
        intermediate: true,
        value: localizedString("map_widget_time")
    )

    static let intermediateArrivalTime = TimeToNavigationPointState(
        title: localizedString("access_arrival_time"),
        iconName: "widget_intermediate_time",
        intermediate: true,
        value: localizedString("access_arrival_time")
    )

    static let destinationTimeToGo = TimeToNavigationPointState(
        title: localizedString("map_widget_time"),
        iconName: "widget_destination_time_to_go",
        intermediate: false,
        value: localizedString("map_widget_time")
    )

    static let destinationArrivalTime = TimeToNavigationPointState(
        title: localizedString("access_arrival_time"),
        iconName: "widget_time_to_distance",
        intermediate: false,
        value: localizedString("access_arrival_time")
    )

    let title: String
    let iconName: String
    let intermediate: Bool
    let value: String

    init(title: String, iconName: String, intermediate: Bool, value: String) {
        self.title = title
        self.iconName = iconName
        self.intermediate = intermediate
        self.value = value
    }

    static func getState(intermediate: Bool, arrivalOtherwiseTimeToGo: Bool) -> TimeToNavigationPointState {
        if intermediate {
            return arrivalOtherwiseTimeToGo ? intermediateArrivalTime : intermediateTimeToGo
        } else {
            return arrivalOtherwiseTimeToGo ? destinationArrivalTime : destinationTimeToGo
        }
    }
    
    func getTitle() -> String {
        intermediate
            ? localizedString("map_widget_time_to_intermediate")
            : localizedString("map_widget_time_to_destination")
    }
    
    func getWidgetTitle() -> String {
        intermediate
            ? appendValueTo(string: localizedString("rendering_attr_smoothness_intermediate_name"))
            : appendValueTo(string: localizedString("route_descr_destination"))
    }
    
    private func appendValueTo(string: String) -> String {
        string + ", \(value)"
    }
}
