//
//  SwitchAppModeCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class SwitchAppModeCommand: KeyEventCommand {
    static let switchToNextId = "switch_app_mode_forward"
    static let switchToPreviusId = "switch_app_mode_backward"
    
    private let moveForward: Bool
    
    init(commandId: String, moveForward: Bool) {
        self.moveForward = moveForward
        super.init(commandId: commandId)
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        OAAppSettings.sharedManager().switchAppMode(toNext: moveForward)
    }
    
    override func toHumanString() -> String {
        localizedString(moveForward ? "key_event_action_next_app_profile" : "key_event_action_previous_app_profile")
    }
}
