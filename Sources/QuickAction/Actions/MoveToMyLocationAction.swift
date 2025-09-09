//
//  MoveToMyLocationAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MoveToMyLocationAction: OAQuickAction {
    static let type = QuickActionType(id: QuickActionIds.moveToMyLocationActionId.rawValue, stringId: "map.move.my_location", cl: MoveToMyLocationAction.self)
        .name(localizedString("quick_action_to_my_location"))
        .nameAction(localizedString("shared_string_move"))
        .iconName("ic_action_my_location")
        .nonEditable()
        .category(QuickActionTypeCategory.mapInteractions.rawValue)
    
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
        localizedString("key_event_action_move_to_my_location")
    }
    
    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_action_my_location")
    }
    
    override func execute() {
        OAMapViewTrackingUtilities.instance().backToLocationImpl()
    }
}
