//
//  OpenSearchViewAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 28.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class OpenSearchViewAction: OAQuickAction {
    static let type = QuickActionType(id: QuickActionIds.openSearchViewAction.rawValue, stringId: "search.view.showhide", cl: OpenSearchViewAction.self)
        .name(localizedString("quick_action_search_view_title"))
        .nameAction(localizedString("shared_string_open"))
        .iconName("ic_action_search_dark")
        .category(QuickActionTypeCategory.interface.rawValue)
        .nonEditable()
    
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
        localizedString("quick_action_search_view_desc")
    }
    
    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_action_search_dark")
    }
    
    override func execute() {
        OARootViewController.instance().mapPanel.open(.REGULAR)
    }
}
