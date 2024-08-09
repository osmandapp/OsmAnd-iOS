//
//  ShowHideHikingRoutesAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 08/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ShowHideHikingRoutesAction: BaseRouteQuickAction {
    
    static var type: QuickActionType?
    
    override class func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.showHideHikingRoutesActionId.rawValue,
                                   stringId: "hiking.routes.showhide",
                                   cl: ShowHideHikingRoutesAction.self)
            .name(Self.getName())
                .nameAction(localizedString("quick_action_verb_show_hide"))
                .iconName("ic_action_trekking_dark")
                .category(QuickActionTypeCategory.configureMap.rawValue)
                .nonEditable()
        }
        return type ?? super.type()
    }
    
    override class func getName() -> String {
        localizedString("rendering_attr_hikingRoutesOSMC_name")
    }
    
    override func isEnabled() -> Bool {
        let styleSettings = OAMapStyleSettings.sharedInstance()
        if let routesParameter = styleSettings?.getParameter(HIKING_ROUTES_OSMC_ATTR) {
            return !routesParameter.storedValue.isEmpty && routesParameter.storedValue != "disabled"
        }
        return false
    }
    
    override func execute() {
        let newValue = isEnabled() ? "disabled" : OAAppSettings.sharedManager().hikingRoutesParameter.get()
        let styleSettings = OAMapStyleSettings.sharedInstance()
        let routesParameter = styleSettings?.getParameter(HIKING_ROUTES_OSMC_ATTR)
        
        if let routesParameter {
            routesParameter.value = newValue
            styleSettings?.save(routesParameter)
        }
    }
}
