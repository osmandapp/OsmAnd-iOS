//
//  ShowHideWindAnimationAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ShowHideWindAnimationAction: BaseWeatherQuickAction {
    private static let type = QuickActionType(id: QuickActionIds.showHideWindAnimationLayerActionId.rawValue, stringId: "wind.animation.layer.showhide", cl: ShowHideWindAnimationAction.self)
        .name(localizedString("wind_animation_layer"))
        .nameAction(localizedString("quick_action_verb_show_hide"))
        .iconName("ic_custom_wind")
        .category(QuickActionTypeCategory.configureMap.rawValue)
        .nonEditable()
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func getText() -> String? {
        localizedString("quick_action_wind_animation_layer")
    }
    
    override func weatherBandIndex() -> EOAWeatherBand {
        .WEATHER_BAND_WIND_ANIMATION
    }
}
