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
    
    private static let type = QuickActionType(id: QuickActionIds.showHideHikingRoutesActionId.rawValue,
                                      stringId: "hiking.routes.showhide",
                                      cl: ShowHideHikingRoutesAction.self)
               .name(localizedString("rendering_attr_hikingRoutesOSMC_name"))
               .nameAction(localizedString("quick_action_verb_show_hide"))
               .iconName("ic_action_trekking_dark")
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
