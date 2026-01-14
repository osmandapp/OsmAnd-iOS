//
//  ShowHideTemperatureAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ShowHideTemperatureAction: BaseWeatherQuickAction {
    private static let type = QuickActionType(id: QuickActionIds.showHideTemperatureLayerActionId.rawValue, stringId: "temperature.layer.showhide", cl: ShowHideTemperatureAction.self)
        .name(localizedString("temperature_layer"))
        .nameAction(localizedString("quick_action_verb_show_hide"))
        .iconName("ic_custom_thermometer")
        .category(QuickActionTypeCategory.configureMap.rawValue)
        .nonEditable()
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func getText() -> String? {
        localizedString("quick_action_temperature_layer")
    }
    
    override func weatherBandIndex() -> EOAWeatherBand {
        .WEATHER_BAND_TEMPERATURE
    }
}
