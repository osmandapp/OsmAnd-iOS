//
//  ShowHideDifficultyClassificationAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 09/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ShowHideDifficultyClassificationAction: BaseRouteQuickAction {
    
    private static let type = QuickActionType(id: QuickActionIds.showHideDifficultyClasificationActionId.rawValue,
                                      stringId: "alpine_hiking.routes.showhide",
                                      cl: ShowHideDifficultyClassificationAction.self)
               .name(localizedString("rendering_attr_alpineHiking_name"))
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
        return styleSettings?.getParameter(ALPINE_HIKING_ATTR).value == "true"
    }
    
    override func execute() {
        let newValue = isEnabled() ? "false" : "true"
        let styleSettings = OAMapStyleSettings.sharedInstance()
        let routesParameter = styleSettings?.getParameter(SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES)
        let nodeParameter = styleSettings?.getParameter(ALPINE_HIKING_ATTR)
        if let nodeParameter {
            nodeParameter.value = newValue
            styleSettings?.save(nodeParameter)
        }
        if let routesParameter {
            styleSettings?.save(routesParameter)
        }
    }
}
