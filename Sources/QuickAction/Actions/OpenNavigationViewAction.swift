//
//  OpenNavigationViewAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class OpenNavigationViewAction: OAQuickAction {
    private static let type = QuickActionType(id: QuickActionIds.openNavigationViewAction.rawValue, stringId: "navigation.view.showhide", cl: OpenNavigationViewAction.self)
        .name(localizedString("quick_action_navigation_view_title"))
        .nameAction(localizedString("shared_string_open"))
        .iconName("ic_custom_navigation")
        .category(QuickActionTypeCategory.interface.rawValue)
        .nonEditable()
    
    override class func getType() -> QuickActionType {
        type
    }

    override init() {
        super.init(actionType: Self.getType())
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func getText() -> String? {
        localizedString("quick_action_navigation_view_desc")
    }
    
    override func execute() {
        OARootViewController.instance().mapPanel.onNavigationClick(false)
    }
}
