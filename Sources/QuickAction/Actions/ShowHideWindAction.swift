//
//  ShowHideWindAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ShowHideWindAction: BaseWeatherQuickAction {
    private static let type = QuickActionType(id: QuickActionIds.showHideWindLayerActionId.rawValue, stringId: "wind.layer.showhide", cl: ShowHideWindAction.self)
        .name(localizedString("wind_layer"))
        .nameAction(localizedString("quick_action_verb_show_hide"))
        .iconName("ic_custom_wind")
        .category(QuickActionTypeCategory.configureMap.rawValue)
        .nonEditable()
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func weatherBandIndex() -> EOAWeatherBand {
        .WEATHER_BAND_WIND_SPEED
    }
}
