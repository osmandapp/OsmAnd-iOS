//
//  ShowHideCycleRoutesAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 08/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ShowHideCycleRoutesAction: BaseRouteQuickAction {
    
    private static let type = QuickActionType(id: QuickActionIds.showHideCycleRoutesActionId.rawValue,
                                     stringId: "cycle.routes.showhide",
                                     cl: ShowHideCycleRoutesAction.self)
              .name(localizedString("rendering_attr_showCycleRoutes_name"))
              .nameAction(localizedString("quick_action_verb_show_hide"))
              .iconName("ic_action_bicycle_dark")
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
        if let routesParameter = styleSettings?.getParameter(SHOW_CYCLE_ROUTES_ATTR) {
            return !routesParameter.storedValue.isEmpty && routesParameter.storedValue == "true"
        }
        return false
    }
    
    override func execute() {
        let isEnabled = isEnabled()
        let styleSettings = OAMapStyleSettings.sharedInstance()
        let routesParameter = styleSettings?.getParameter(SHOW_CYCLE_ROUTES_ATTR)
        let nodeParameter = styleSettings?.getParameter(CYCLE_NODE_NETWORK_ROUTES_ATTR)
        
        if let nodeParameter {
            nodeParameter.value = isEnabled ? "false" : OAAppSettings.sharedManager().cycleRoutesParameter.get()
            styleSettings?.save(nodeParameter)
        }
        if let routesParameter {
            routesParameter.value = isEnabled ? "false" : "true"
            styleSettings?.save(routesParameter)
        }
    }
}
