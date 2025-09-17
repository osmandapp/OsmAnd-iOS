//
//  ToggleDrawerCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class ToggleDrawerCommand: KeyEventCommand {
    static let id = "toggle_drawer"
    
    override func toHumanString() -> String {
        localizedString("key_event_action_toggle_drower")
    }
}
