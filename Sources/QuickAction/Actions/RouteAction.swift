//
//  RouteAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class RouteAction: OAQuickAction {
    static let type = QuickActionType(id: QuickActionIds.routeActionId.rawValue, stringId: "route.add", cl: RouteAction.self)
        .name(localizedString("quick_action_new_route"))
        .nameAction(localizedString("shared_string_create"))
        .iconName("ic_custom_plan_route")
        .nonEditable()
        .category(QuickActionTypeCategory.myPlaces.rawValue)
    
    override init() {
        super.init(actionType: Self.type)
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func getText() -> String? {
        localizedString("quick_action_add_route_descr")
    }
    
    override func execute() {
        OARootViewController.instance().mapPanel.showScrollableHudViewController(OARoutePlanningHudViewController())
    }
}
