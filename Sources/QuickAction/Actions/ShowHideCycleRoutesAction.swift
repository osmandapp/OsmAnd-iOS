//
//  ShowHideCycleRoutesAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 08/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class ShowHideCycleRoutesAction: OAQuickAction {
    
    private static var type: QuickActionType?
    
    private var setting: OAAppSettings?
    private var styleSettings: OAMapStyleSettings?
    private var routesParameter: OAMapStyleParameter?
    private var cycleNode: OAMapStyleParameter?
    
    static func getQuickActionType() -> QuickActionType {
        if type == nil {
            type = QuickActionType(id: QuickActionIds.showHideCycleRoutesActionId.rawValue,
                             stringId: "cycle.routes.showhide",
                                   cl: ShowHideCycleRoutesAction.self)
                .name(localizedString("rendering_attr_showCycleRoutes_name"))
                .nameAction(localizedString("quick_action_verb_show_hide"))
                .iconName("ic_action_bicycle_dark")
                .category(QuickActionTypeCategory.configureMap.rawValue)
                .nonEditable()
        }
        return type ?? super.type()
    }
    
    override init() {
        super.init(actionType: ShowHideCycleRoutesAction.getQuickActionType())
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func commonInit() {
        setting = OAAppSettings.sharedManager()
        styleSettings = OAMapStyleSettings.sharedInstance()
        routesParameter = styleSettings?.getParameter("showCycleRoutes")
        cycleNode = styleSettings?.getParameter(CYCLE_NODE_NETWORK_ROUTES_ATTR)
    }
    
    private func isEnabled() -> Bool {
        if let routesParameter {
            return !routesParameter.storedValue.isEmpty && routesParameter.storedValue == "true"
        }
        return false
    }
    
    override func isActionWithSlash() -> Bool {
        isEnabled()
    }
    
    override func getStateName() -> String? {
        let actionName = localizedString(isEnabled() ? "shared_string_hide" : "shared_string_show")
        return String(format: localizedString("ltr_or_rtl_combine_via_dash"), actionName, localizedString("rendering_attr_showCycleRoutes_name"))
    }
    
    override func execute() {
        let newValue = isEnabled() ? "false" : "true"
        if let routesParameter {
            routesParameter.value = newValue
            styleSettings?.save(routesParameter)
        }
        if let cycleNode {
            cycleNode.value = newValue
            styleSettings?.save(cycleNode)
        }
    }
}
