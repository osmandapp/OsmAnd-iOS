//
//  ShowHideDrawerAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ShowHideDrawerAction: OAQuickAction {
    static let type = QuickActionType(id: QuickActionIds.showHideDrawerAction.rawValue, stringId: "drawer.showhide", cl: ShowHideDrawerAction.self)
        .name(localizedString("quick_action_drawer_title"))
        .nameAction(localizedString("quick_action_verb_show_hide"))
        .iconName("ic_custom_drawer") // TODO: - https://github.com/osmandapp/OsmAnd-iOS/issues/2818
        .nonEditable()
        .category(QuickActionTypeCategory.interface.rawValue)
    
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
        localizedString("quick_action_drawer_desc")
    }
    
    override func execute() {
        OARootViewController.instance().toggleLeftPanel(self)
    }
}
