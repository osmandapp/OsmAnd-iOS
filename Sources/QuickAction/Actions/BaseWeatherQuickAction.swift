//
//  BaseWeatherQuickAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class BaseWeatherQuickAction: OAQuickAction {
    
    override init() {
        super.init(actionType: Self.getType())
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func execute() {
        guard let band = OAWeatherHelperBridge.weatherBand(forIndex: weatherBandIndex()), let plugin = OAPluginsHelper.getPlugin(OAWeatherPlugin.self) as? OAWeatherPlugin else { return }
        let visible = !band.isBandVisible()
        band.setSelect(visible)
        let anyVisible = !OAWeatherHelperBridge.allLayersAreDisabled()
        plugin.weatherChanged(anyVisible)
    }
    
    override func getStateName() -> String? {
        let nameRes = Self.getType().name ?? ""
        let actionName = localizedString(isActionWithSlash() ? "shared_string_hide" : "shared_string_show")
        return String(format: localizedString("ltr_or_rtl_combine_via_dash"), actionName, nameRes)
    }
    
    override func isActionWithSlash() -> Bool {
        OAWeatherHelperBridge.weatherBand(forIndex: weatherBandIndex())?.isBandVisible() ?? false
    }
    
    func weatherBandIndex() -> EOAWeatherBand {
        fatalError("Override in subclass")
    }
}
