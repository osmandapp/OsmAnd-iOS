//
//  ShowHideDrawerAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 28.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class ShowHideDrawerAction: OAQuickAction {
    static let type = QuickActionType(id: QuickActionIds.showHideDrawerAction.rawValue, stringId: "drawer.showhide", cl: ShowHideDrawerAction.self)
        .name(localizedString("quick_action_drawer_title"))
        .nameAction(localizedString("quick_action_verb_show_hide"))
        .iconName("ic_action_drawer")
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
    
    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_action_drawer")
    }
    
    override func execute() {
        OARootViewController.instance().toggleLeftPanel(self)
    }
}
