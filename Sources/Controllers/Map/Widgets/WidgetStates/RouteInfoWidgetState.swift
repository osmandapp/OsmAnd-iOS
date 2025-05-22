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
    
    func getDefaultView() -> DisplayValue {
        getDefaultView(with: OAAppSettings.sharedManager().applicationMode.get())
    }
    
    func getDefaultView(with appMode: OAApplicationMode) -> DisplayValue {
        getDefaultView(with: appMode, widgetConfigurationParams: nil, isCreate: false)
    }
    
    func getDefaultView(with appMode: OAApplicationMode,
                        widgetConfigurationParams: [String: Any]?,
                        isCreate: Bool) -> DisplayValue {
        var currentValue = defaultViewPref.defValue
        if let widgetConfigurationParams,
           let value = widgetConfigurationParams[Self.defaultViewId] as? String {
            switch value {
            case DisplayValue.arrivalTime.key: currentValue = DisplayValue.arrivalTime.rawValue
            case DisplayValue.timeToGo.key: currentValue = DisplayValue.timeToGo.rawValue
            case DisplayValue.distance.key: currentValue = DisplayValue.distance.rawValue
            default: break
            }
        } else if !isCreate {
            currentValue = defaultViewPref.get(appMode)
        }
        return DisplayValue(rawValue: currentValue)!
    }
    
    func getDisplayPriority() -> DisplayPriority {
        getDisplayPriority(with: OAAppSettings.sharedManager().applicationMode.get())
    }
    
    func getDisplayPriority(with appMode: OAApplicationMode) -> DisplayPriority {
        getDisplayPriority(with: appMode, widgetConfigurationParams: nil, isCreate: false)
    }
    
    func getDisplayPriority(with appMode: OAApplicationMode,
                            widgetConfigurationParams: [String: Any]?,
                            isCreate: Bool) -> DisplayPriority {
        var currentValue = displayPriorityPref.defValue
        if let widgetConfigurationParams,
           let value = widgetConfigurationParams[Self.displayPriorityId] as? String {
            switch value {
            case DisplayPriority.intermediateFirst.key: currentValue = DisplayPriority.intermediateFirst.rawValue
            case DisplayPriority.destinationFirst.key: currentValue = DisplayPriority.destinationFirst.rawValue
            default: break
            }
        } else if !isCreate {
            currentValue = displayPriorityPref.get(appMode)
        }
        return DisplayPriority(rawValue: currentValue)!
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
        let preference = OAAppSettings.sharedManager().registerWidgetDefaultViewPreference(prefId, defValue: DisplayValue.arrivalTime.rawValue)!
        if let widgetValue = widgetParams?[Self.defaultViewId] as? String {
            switch widgetValue {
            case DisplayValue.arrivalTime.key: preference.set(DisplayValue.arrivalTime.rawValue)
            case DisplayValue.timeToGo.key: preference.set(DisplayValue.timeToGo.rawValue)
            case DisplayValue.distance.key: preference.set(DisplayValue.distance.rawValue)
            default: break
            }
        }
        return preference
    }

    private static func registerDisplayPriorityPreferenceWith(customId: String?, widgetParams: ([String: Any])? = nil) -> OACommonWidgetDisplayPriority {
        var prefId = Self.displayPriorityId
        if let customId, !customId.isEmpty {
            prefId += "_" + customId
        }
        let preference = OAAppSettings.sharedManager().registerWidgetDisplayPriorityPreference(prefId, defValue: DisplayPriority.destinationFirst.rawValue)!
        if let widgetValue = widgetParams?[Self.displayPriorityId] as? String {
            switch widgetValue {
            case DisplayPriority.intermediateFirst.key: preference.set(DisplayPriority.intermediateFirst.rawValue)
            case DisplayPriority.destinationFirst.key: preference.set(DisplayPriority.destinationFirst.rawValue)
            default: break
            }
        }
        return preference
    }
}
