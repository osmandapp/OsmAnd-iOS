//
//  ShowHideHorseRoutesAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 09/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class ShowHideHorseRoutesAction: BaseRouteQuickAction {
    
    static var type: QuickActionType?
    
    override static func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.showHideHorseRoutesActionId.rawValue,
                                   stringId: "alpine_hiking.routes.showhide",
                                   cl: ShowHideHorseRoutesAction.self)
            .name(Self.getName())
                .nameAction(localizedString("quick_action_verb_show_hide"))
                .iconName("ic_action_horse")
                .category(QuickActionTypeCategory.configureMap.rawValue)
                .nonEditable()
        }
        return type ?? super.type()
    }
    
    override static func getName() -> String {
        localizedString("rendering_attr_horseRoutes_name")
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
