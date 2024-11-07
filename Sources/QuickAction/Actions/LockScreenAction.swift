//
//  LockScreenAction.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 07.11.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class LockScreenAction: OAQuickAction {
    static let type = QuickActionType(id: QuickActionIds.lockScreenAction.rawValue,
                                      stringId: "lock_screen_action",
                                      cl: LockScreenAction.self)
        .name(localizedString("lock_screen"))
        .nameAction(localizedString("quick_action_verb_turn_on_off"))
        .iconName("ic_custom_ui_customization")
        .category(QuickActionTypeCategory.interface.rawValue)
    
    private let settings = OAAppSettings.sharedManager()!
    
    override init() {
        super.init(actionType: Self.type)
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    //    override func getName() -> String {
    //        localizedString("position_on_map")
    //    }
    
    override func getIconResName() -> String {
        return "ic_custom_lock_closed"
        //        switch EOAPositionPlacement(rawValue: Int(settings.positionPlacementOnMap.get())) {
        //        case .auto: "ic_custom_display_position_center"
        //        case .center: "ic_custom_display_position_bottom"
        //        default: "ic_custom_display_position_automatic"
        //        }
    }
    
    //    override func getStateName() -> String {
    //        String(format: localizedString("ltr_or_rtl_combine_via_dash"), localizedString("shared_string_change"), getName())
    //    }
    
    //    override func getText() -> String {
    //        localizedString("quick_action_toggle_preference")
    //    }
    
    override func execute() {
        //        var newState: Int32
        //        switch EOAPositionPlacement(rawValue: Int(settings.positionPlacementOnMap.get())) {
        //        case .auto: newState = Int32(EOAPositionPlacement.center.rawValue)
        //        case .center: newState = Int32(EOAPositionPlacement.bottom.rawValue)
        //        default: newState = Int32(EOAPositionPlacement.auto.rawValue)
        //        }
        //        settings.positionPlacementOnMap.set(newState)
    }
}
