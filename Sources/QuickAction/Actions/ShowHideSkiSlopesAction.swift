//
//  ShowHideSkiSlopesAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 09/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class ShowHideSkiSlopesAction: BaseRouteQuickAction {
    
    static var type: QuickActionType?
    
    override static func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.showHideSkiSlopesRoutesActionId.rawValue,
                                   stringId: "ski_slopes.routes.showhide",
                                   cl: ShowHideSkiSlopesAction.self)
            .name(Self.getName())
                .nameAction(localizedString("quick_action_verb_show_hide"))
                .iconName("ic_action_skiing")
                .category(QuickActionTypeCategory.configureMap.rawValue)
                .nonEditable()
        }
        return type ?? super.type()
    }
    
    override static func getName() -> String {
        localizedString("rendering_attr_pisteRoutes_name")
    }
    
    override func isEnabled() -> Bool {
        let styleSettings = OAMapStyleSettings.sharedInstance()
        if let paraeter = styleSettings?.getParameter(PISTE_ROUTES_ATTR) {
            return paraeter.value == "true"
        }
        return false
    }
    
    override func execute() {
        let newValue = isEnabled() ? "false" : "true"
        let styleSettings = OAMapStyleSettings.sharedInstance()

        let nodeParameter = styleSettings?.getParameter(PISTE_ROUTES_ATTR)
        if let nodeParameter {
            nodeParameter.value = newValue
            styleSettings?.save(nodeParameter)
        }
    }
}
