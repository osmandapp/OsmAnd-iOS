//
//  NavigatePreviousScreenAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 28.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class NavigatePreviousScreenAction: OAQuickAction {
    static let type = QuickActionType(id: QuickActionIds.navigatePreviousScreenAction.rawValue, stringId: "navigate.previous.screen", cl: NavigatePreviousScreenAction.self)
        .name(localizedString("quick_action_previous_screen_title"))
        .nameAction(localizedString("quick_action_verb_navigate"))
        .iconName("ic_action_previous_screen")
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
        localizedString("quick_action_previous_screen_desc")
    }
    
    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_action_previous_screen")
    }
    
    override func execute() {
        OARootViewController.instance().mapPanel.navigationController?.popViewController(animated: true)
    }
}
