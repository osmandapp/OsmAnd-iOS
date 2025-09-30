//
//  ShowHideRunningRoutesAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 09/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ShowHideRunningRoutesAction: BaseRouteQuickAction {
    
    private static let type = QuickActionType(id: QuickActionIds.showHideRunningRoutesActionId.rawValue,
                                      stringId: "running.routes.showhide",
                                      cl: ShowHideRunningRoutesAction.self)
               .name(localizedString("rendering_attr_showRunningRoutes_name"))
               .nameAction(localizedString("quick_action_verb_show_hide"))
               .iconName("mx_running")
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
