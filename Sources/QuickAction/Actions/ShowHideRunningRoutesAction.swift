//
//  ShowHideRunningRoutesAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 09/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class ShowHideRunningRoutesAction: BaseRouteQuickAction {
    
    static var type: QuickActionType?
    
    override static func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.showHideRunningRoutesActionId.rawValue,
                                   stringId: "running.routes.showhide",
                                   cl: ShowHideRunningRoutesAction.self)
            .name(Self.getName())
                .nameAction(localizedString("quick_action_verb_show_hide"))
                .iconName("mx_running")
                .category(QuickActionTypeCategory.configureMap.rawValue)
                .nonEditable()
        }
        return type ?? super.type()
    }
    
    override static func getName() -> String {
        localizedString("rendering_attr_showRunningRoutes_name")
    }
    
    override func isEnabled() -> Bool {
        let styleSettings = OAMapStyleSettings.sharedInstance()
        return styleSettings?.getParameter(SHOW_RUNNING_ROUTES_ATTR).value == "true"
    }
    
    override func execute() {
        let newValue = isEnabled() ? "false" : "true"
        let styleSettings = OAMapStyleSettings.sharedInstance()

        let nodeParameter = styleSettings?.getParameter(SHOW_RUNNING_ROUTES_ATTR)
        if let nodeParameter {
            nodeParameter.value = newValue
            styleSettings?.save(nodeParameter)
        }
    }
}
