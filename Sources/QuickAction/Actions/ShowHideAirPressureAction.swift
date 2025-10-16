//
//  ShowHideAirPressureAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ShowHideAirPressureAction: BaseWeatherQuickAction {
    private static let type = QuickActionType(id: QuickActionIds.showHideAirPressureLayerActionId.rawValue, stringId: "pressure.layer.showhide", cl: ShowHideAirPressureAction.self)
        .name(localizedString("pressure_layer"))
        .nameAction(localizedString("quick_action_verb_show_hide"))
        .iconName("ic_custom_air_pressure")
        .category(QuickActionTypeCategory.configureMap.rawValue)
        .nonEditable()
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func weatherBandIndex() -> EOAWeatherBand {
        .WEATHER_BAND_PRESSURE
    }
}
