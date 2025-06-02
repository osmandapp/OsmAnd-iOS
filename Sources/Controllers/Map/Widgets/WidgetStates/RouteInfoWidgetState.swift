//
//  RouteInfoWidgetState.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 08.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class RouteInfoWidgetState: OAWidgetState {
    private static let defaultViewId = "route_info_widget_display_mode"
    private static let displayPriorityId = "route_info_widget_display_priority"
    
    let defaultViewPref: OACommonWidgetDefaultView
    let displayPriorityPref: OACommonWidgetDisplayPriority
    
    init(customId: String?, widgetParams: ([String: Any])?) {
        defaultViewPref = RouteInfoWidgetState.registerDefaultViewPreferenceWith(customId: customId, widgetParams: widgetParams)
        displayPriorityPref = RouteInfoWidgetState.registerDisplayPriorityPreferenceWith(customId: customId, widgetParams: widgetParams)
    }
    
    func getDefaultView() -> RouteInfoDisplayValue {
        getDefaultView(with: OAAppSettings.sharedManager().applicationMode.get())
    }
    
    func getDefaultView(with appMode: OAApplicationMode) -> RouteInfoDisplayValue {
        getDefaultView(with: appMode, widgetConfigurationParams: nil, isCreate: false)
    }
    
    func getDefaultView(with appMode: OAApplicationMode,
                        widgetConfigurationParams: [String: Any]?,
                        isCreate: Bool) -> RouteInfoDisplayValue {
        var currentValue = defaultViewPref.defValue
        if let widgetConfigurationParams,
           let value = widgetConfigurationParams[Self.defaultViewId] as? String {
            switch value {
            case RouteInfoDisplayValue.arrivalTime.key:
                currentValue = RouteInfoDisplayValue.arrivalTime.rawValue
            case RouteInfoDisplayValue.timeToGo.key:
                currentValue = RouteInfoDisplayValue.timeToGo.rawValue
            case RouteInfoDisplayValue.distance.key:
                currentValue = RouteInfoDisplayValue.distance.rawValue
            default:
                break
            }
        } else if !isCreate {
            currentValue = defaultViewPref.get(appMode)
        }
        return RouteInfoDisplayValue(rawValue: currentValue)!
    }
    
    func getDisplayPriority() -> RouteInfoDisplayPriority {
        getDisplayPriority(with: OAAppSettings.sharedManager().applicationMode.get())
    }
    
    func getDisplayPriority(with appMode: OAApplicationMode) -> RouteInfoDisplayPriority {
        getDisplayPriority(with: appMode, widgetConfigurationParams: nil, isCreate: false)
    }
    
    func getDisplayPriority(with appMode: OAApplicationMode,
                            widgetConfigurationParams: [String: Any]?,
                            isCreate: Bool) -> RouteInfoDisplayPriority {
        var currentValue = displayPriorityPref.defValue
        if let widgetConfigurationParams,
           let value = widgetConfigurationParams[Self.displayPriorityId] as? String {
            switch value {
            case RouteInfoDisplayPriority.intermediateFirst.key:
                currentValue = RouteInfoDisplayPriority.intermediateFirst.rawValue
            case RouteInfoDisplayPriority.destinationFirst.key:
                currentValue = RouteInfoDisplayPriority.destinationFirst.rawValue
            default:
                break
            }
        } else if !isCreate {
            currentValue = displayPriorityPref.get(appMode)
        }
        return RouteInfoDisplayPriority(rawValue: currentValue)!
    }
    
    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerDefaultViewPreferenceWith(customId: customId).set(defaultViewPref.get(appMode), mode: appMode)
        Self.registerDisplayPriorityPreferenceWith(customId: customId).set(displayPriorityPref.get(appMode), mode: appMode)
    }
    
    private static func registerDefaultViewPreferenceWith(customId: String?, widgetParams: ([String: Any])? = nil) -> OACommonWidgetDefaultView {
        var prefId = Self.defaultViewId
        if let customId, !customId.isEmpty {
            prefId += "_" + customId
        }
        let preference = OAAppSettings.sharedManager().registerWidgetDefaultViewPreference(prefId, defValue: RouteInfoDisplayValue.arrivalTime.rawValue)!
        if let widgetValue = widgetParams?[Self.defaultViewId] as? String {
            switch widgetValue {
            case RouteInfoDisplayValue.arrivalTime.key:
                preference.set(RouteInfoDisplayValue.arrivalTime.rawValue)
            case RouteInfoDisplayValue.timeToGo.key:
                preference.set(RouteInfoDisplayValue.timeToGo.rawValue)
            case RouteInfoDisplayValue.distance.key:
                preference.set(RouteInfoDisplayValue.distance.rawValue)
            default:
                break
            }
        }
        return preference
    }

    private static func registerDisplayPriorityPreferenceWith(customId: String?, widgetParams: ([String: Any])? = nil) -> OACommonWidgetDisplayPriority {
        var prefId = Self.displayPriorityId
        if let customId, !customId.isEmpty {
            prefId += "_" + customId
        }
        let preference = OAAppSettings.sharedManager().registerWidgetDisplayPriorityPreference(prefId, defValue: RouteInfoDisplayPriority.destinationFirst.rawValue)!
        if let widgetValue = widgetParams?[Self.displayPriorityId] as? String {
            switch widgetValue {
            case RouteInfoDisplayPriority.intermediateFirst.key:
                preference.set(RouteInfoDisplayPriority.intermediateFirst.rawValue)
            case RouteInfoDisplayPriority.destinationFirst.key:
                preference.set(RouteInfoDisplayPriority.destinationFirst.rawValue)
            default:
                break
            }
        }
        return preference
    }
}
