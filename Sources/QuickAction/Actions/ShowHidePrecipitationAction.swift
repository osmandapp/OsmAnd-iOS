//
//  ShowHidePrecipitationAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ShowHidePrecipitationAction: BaseWeatherQuickAction {
    private static let type = QuickActionType(id: QuickActionIds.showHidePrecipitationLayerActionId.rawValue, stringId: "precipitation.layer.showhide", cl: ShowHidePrecipitationAction.self)
        .name(localizedString("precipitation_layer"))
        .nameAction(localizedString("quick_action_verb_show_hide"))
        .iconName("ic_custom_precipitation")
        .category(QuickActionTypeCategory.configureMap.rawValue)
        .nonEditable()
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func getText() -> String? {
        localizedString("quick_action_precipitation_layer")
    }
    
    override func weatherBandIndex() -> EOAWeatherBand {
        .WEATHER_BAND_PRECIPITATION
    }
}
