//
//  ShowHideMtbRoutesAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 08/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ShowHideMtbRoutesAction: BaseRouteQuickAction {
    
    private static let type = QuickActionType(id: QuickActionIds.showHideMtbRoutesActionId.rawValue,
                                      stringId: "mtb.routes.showhidee",
                                      cl: ShowHideMtbRoutesAction.self)
               .name(localizedString("rendering_attr_showMtbRoutes_name"))
               .nameAction(localizedString("quick_action_verb_show_hide"))
               .iconName("ic_action_mountain_bike")
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
        if let routesParameter = styleSettings?.getParameter(SHOW_MTB_ROUTES) {
            return !routesParameter.storedValue.isEmpty && routesParameter.storedValue == "true"
        }
        return false
    }
    
    override func execute() {
        let newValue = isEnabled() ? "false" : "true"
        let routesEnabled = !isEnabled()
        
        let styleSettings = OAMapStyleSettings.sharedInstance()
        let routesParameter = styleSettings?.getParameter(SHOW_MTB_ROUTES)
        routesParameter?.value = newValue
        
        let mountainBikeRoutesParameter = OAAppSettings.sharedManager().mountainBikeRoutesParameter.get()
        
        let mtbScale = styleSettings?.getParameter(SHOW_MTB_SCALE)
        if let mtbScale {
            mtbScale.value = routesEnabled && mountainBikeRoutesParameter == mtbScale.name ? "true" : "false"
            styleSettings?.save(mtbScale)
        }
        if let mtbScaleUphill = styleSettings?.getParameter(SHOW_MTB_SCALE_UPHILL) {
            mtbScaleUphill.value = mtbScale != nil ? mtbScale?.value : "false"
            styleSettings?.save(mtbScaleUphill)
        }
        if let imbaTrails = styleSettings?.getParameter(SHOW_MTB_SCALE_IMBA_TRAILS) {
            imbaTrails.value = routesEnabled && mountainBikeRoutesParameter == imbaTrails.name ? "true" : "false"
            styleSettings?.save(imbaTrails)
        }
        styleSettings?.save(routesParameter)
    }
}
