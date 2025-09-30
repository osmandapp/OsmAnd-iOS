//
//  ShowHideHorseRoutesAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 09/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ShowHideHorseRoutesAction: BaseRouteQuickAction {
    
    private static let type = QuickActionType(id: QuickActionIds.showHideHorseRoutesActionId.rawValue,
                                      stringId: "horse.routes.showhide",
                                      cl: ShowHideHorseRoutesAction.self)
               .name(localizedString("rendering_attr_horseRoutes_name"))
               .nameAction(localizedString("quick_action_verb_show_hide"))
               .iconName("ic_action_horse")
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
        return styleSettings?.getParameter(HORSE_ROUTES_ATTR).value == "true"
    }
    
    override func execute() {
        let newValue = isEnabled() ? "false" : "true"
        let styleSettings = OAMapStyleSettings.sharedInstance()

        let nodeParameter = styleSettings?.getParameter(HORSE_ROUTES_ATTR)
        if let nodeParameter {
            nodeParameter.value = newValue
            styleSettings?.save(nodeParameter)
        }
    }
}
