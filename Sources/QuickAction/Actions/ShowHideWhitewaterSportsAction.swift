//
//  ShowHideWhitewaterSportsAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 09/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ShowHideWhitewaterSportsAction: BaseRouteQuickAction {
    
    private static let type = QuickActionType(id: QuickActionIds.showHideWhitewaterSportsRoutesActionId.rawValue,
                                      stringId: "whitewater_sports.routes.showhide",
                                      cl: ShowHideWhitewaterSportsAction.self)
               .name(localizedString("rendering_attr_whiteWaterSports_name"))
               .nameAction(localizedString("quick_action_verb_show_hide"))
               .iconName("ic_action_kayak")
               .category(QuickActionTypeCategory.configureMap.rawValue)
               .nonEditable()
    
    override class func getType() -> QuickActionType {
        type
    }

    override class func getName() -> String {
        type.name!
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
