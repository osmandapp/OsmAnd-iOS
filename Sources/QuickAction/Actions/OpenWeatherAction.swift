//
//  OpenWeatherAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class OpenWeatherAction: OAQuickAction {
    private static let type = QuickActionType(id: QuickActionIds.openWeatherActionId.rawValue, stringId: "weather.forecast.open", cl: OpenWeatherAction.self)
        .name(localizedString("weather_screen"))
        .nameAction(localizedString("shared_string_open"))
        .iconName("ic_custom_umbrella")
        .nonEditable()
        .category(QuickActionTypeCategory.configureMap.rawValue)
    
    override class func getType() -> QuickActionType {
        type
    }

    override init() {
        super.init(actionType: Self.getType())
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func getText() -> String? {
        localizedString("open_weather_action_description")
    }
    
    override func execute() {
        guard let weatherPlugin = OAPluginsHelper.getPlugin(OAWeatherPlugin.self) as? OAWeatherPlugin else {
            return
        }
        
        if !OAPluginsHelper.isEnabled(OAWeatherPlugin.self) {
            OAPluginsHelper.enable(weatherPlugin, enable: true)
            OAIAPHelper.sharedInstance().enableProduct(weatherPlugin.getId())
        }
        
        OARootViewController.instance().mapPanel.hudViewController?.changeWeatherToolbarVisible()
    }
}
