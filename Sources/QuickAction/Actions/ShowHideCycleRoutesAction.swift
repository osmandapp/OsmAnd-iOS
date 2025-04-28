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
    
    static var type: QuickActionType?
    
    override class func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.showHideCycleRoutesActionId.rawValue, 
                                   stringId: "cycle.routes.showhide",
                                   cl: ShowHideCycleRoutesAction.self)
            .name(Self.getName())
                .nameAction(localizedString("quick_action_verb_show_hide"))
                .iconName("ic_action_bicycle_dark")
                .category(QuickActionTypeCategory.configureMap.rawValue)
                .nonEditable()
        }
        return type ?? super.type()
    }
    
    override class func getName() -> String {
        localizedString("rendering_attr_showCycleRoutes_name")
    }
    
    override func isEnabled() -> Bool {
        let styleSettings = OAMapStyleSettings.sharedInstance()
        if let routesParameter = styleSettings?.getParameter(SHOW_CYCLE_ROUTES_ATTR) {
            return !routesParameter.storedValue.isEmpty && routesParameter.storedValue == "true"
        }
        return false
    }
    
    override func execute() {
        let newValue = isEnabled() ? "false" : "true"
        let styleSettings = OAMapStyleSettings.sharedInstance()
        let routesParameter = styleSettings?.getParameter(SHOW_CYCLE_ROUTES_ATTR)
        let nodeParameter = styleSettings?.getParameter(CYCLE_NODE_NETWORK_ROUTES_ATTR)
        
        if let nodeParameter {
            nodeParameter.value = newValue
            styleSettings?.save(nodeParameter)
        }
        if let routesParameter {
            routesParameter.value = newValue
            styleSettings?.save(routesParameter)
        }
    }
}
