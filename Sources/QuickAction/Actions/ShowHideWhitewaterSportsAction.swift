//
//  ShowHideWhitewaterSportsAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 09/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class ShowHideWhitewaterSportsAction: BaseRouteQuickAction {
    
    static var type: QuickActionType?
    
    override static func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.showHideWhitewaterSportsRoutesActionId.rawValue,
                                   stringId: "whitewater_sports.routes.showhide",
                                   cl: ShowHideWhitewaterSportsAction.self)
            .name(Self.getName())
                .nameAction(localizedString("quick_action_verb_show_hide"))
                .iconName("ic_action_kayak")
                .category(QuickActionTypeCategory.configureMap.rawValue)
                .nonEditable()
        }
        return type ?? super.type()
    }
    
    override static func getName() -> String {
        localizedString("rendering_attr_whiteWaterSports_name")
    }
    
    override func isEnabled() -> Bool {
        let styleSettings = OAMapStyleSettings.sharedInstance()
        return styleSettings?.getParameter(WHITE_WATER_SPORTS_ATTR).value == "true"
    }
    
    override func execute() {
        let newValue = isEnabled() ? "false" : "true"
        let styleSettings = OAMapStyleSettings.sharedInstance()

        let nodeParameter = styleSettings?.getParameter(WHITE_WATER_SPORTS_ATTR)
        if let nodeParameter {
            nodeParameter.value = newValue
            styleSettings?.save(nodeParameter)
        }
    }
}
