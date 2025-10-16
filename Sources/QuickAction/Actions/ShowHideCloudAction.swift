//
//  ShowHideCloudAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ShowHideCloudAction: BaseWeatherQuickAction {
    private static let type = QuickActionType(id: QuickActionIds.showHideCloudLayerActionId.rawValue, stringId: "cloud.layer.showhide", cl: ShowHideCloudAction.self)
        .name(localizedString("cloud_layer"))
        .nameAction(localizedString("quick_action_verb_show_hide"))
        .iconName("ic_custom_clouds")
        .category(QuickActionTypeCategory.configureMap.rawValue)
        .nonEditable()
    
    override class func getType() -> QuickActionType {
        type
    }
    
    override func weatherBandIndex() -> EOAWeatherBand {
        .WEATHER_BAND_CLOUD
    }
}
