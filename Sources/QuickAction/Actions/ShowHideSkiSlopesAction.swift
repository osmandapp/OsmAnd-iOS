//
//  ShowHideSkiSlopesAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 09/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ShowHideSkiSlopesAction: BaseRouteQuickAction {
    
    private static let type = QuickActionType(id: QuickActionIds.showHideSkiSlopesRoutesActionId.rawValue,
                                      stringId: "ski_slopes.routes.showhide",
                                      cl: ShowHideSkiSlopesAction.self)
               .name(localizedString("rendering_attr_pisteRoutes_name"))
               .nameAction(localizedString("quick_action_verb_show_hide"))
               .iconName("ic_action_skiing")
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
        if let parameter = styleSettings?.getParameter(PISTE_ROUTES_ATTR) {
            return parameter.value == "true"
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
