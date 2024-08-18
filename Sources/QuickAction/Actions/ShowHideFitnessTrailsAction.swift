//
//  ShowHideFitnessTrailsAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 09/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ShowHideFitnessTrailsAction: BaseRouteQuickAction {
    
    static var type: QuickActionType?
    
    override class func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.showHideFitnessTrailsRoutesActionId.rawValue,
                                   stringId: "fitness_trails.routes.showhide",
                                   cl: ShowHideFitnessTrailsAction.self)
            .name(Self.getName())
                .nameAction(localizedString("quick_action_verb_show_hide"))
                .iconName("mx_sport_athletics")
                .category(QuickActionTypeCategory.configureMap.rawValue)
                .nonEditable()
        }
        return type ?? super.type()
    }
    
    override class func getName() -> String {
        localizedString("rendering_attr_showFitnessTrails_name")
    }
    
    override func isEnabled() -> Bool {
        let styleSettings = OAMapStyleSettings.sharedInstance()
        return styleSettings?.getParameter(SHOW_FITNESS_TRAILS_ATTR).value == "true"
    }
    
    override func execute() {
        let newValue = isEnabled() ? "false" : "true"
        let styleSettings = OAMapStyleSettings.sharedInstance()

        let nodeParameter = styleSettings?.getParameter(SHOW_FITNESS_TRAILS_ATTR)
        if let nodeParameter {
            nodeParameter.value = newValue
            styleSettings?.save(nodeParameter)
        }
    }
}
