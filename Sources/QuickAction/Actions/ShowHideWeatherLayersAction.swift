//
//  ShowHideWeatherLayersAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ShowHideWeatherLayersAction: OAQuickAction {
    private static let type = QuickActionType(id: QuickActionIds.showHideWeatherLayersActionId.rawValue, stringId: "weather.layers.showhide", cl: ShowHideWeatherLayersAction.self)
        .name(localizedString("weather_layers"))
        .nameAction(localizedString("quick_action_verb_show_hide"))
        .iconName("ic_custom_umbrella")
        .nonEditable()
        .category(QuickActionTypeCategory.configureMap.rawValue)
    
    override init() {
        super.init(actionType: Self.getType())
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func getText() -> String? {
        localizedString("quick_action_weather_layers")
    }
    
    override func getStateName() -> String? {
        let nameRes = Self.getType().name ?? ""
        let actionName = localizedString(isActionWithSlash() ? "shared_string_hide" : "shared_string_show")
        return String(format: localizedString("ltr_or_rtl_combine_via_dash"), actionName, nameRes)
    }
    
    override func execute() {
        guard let plugin = OAPluginsHelper.getPlugin(OAWeatherPlugin.self) as? OAWeatherPlugin, plugin.isEnabled(), let app = OsmAndApp.swiftInstance() else { return }
        app.data.weather = !app.data.weather
        plugin.updateLayers()
    }
    
    override func isActionWithSlash() -> Bool {
        guard let plugin = OAPluginsHelper.getPlugin(OAWeatherPlugin.self) as? OAWeatherPlugin, plugin.isEnabled() else { return false }
        return OsmAndApp.swiftInstance().data.weather
    }
}
