//
//  MoveToMyLocationAction.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 12.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MoveToMyLocationAction: OAQuickAction {
    private static let type = QuickActionType(id: QuickActionIds.moveToMyLocationActionId.rawValue, stringId: "map.move.my_location", cl: MoveToMyLocationAction.self)
        .name(localizedString("quick_action_to_my_location"))
        .nameAction(localizedString("shared_string_move"))
        .iconName("ic_custom_location_user")
        .nonEditable()
        .category(QuickActionTypeCategory.mapInteractions.rawValue)
    
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
        localizedString("key_event_action_move_to_my_location")
    }
    
    override func execute() {
        OAMapViewTrackingUtilities.instance().backToLocationImpl()
    }
}
