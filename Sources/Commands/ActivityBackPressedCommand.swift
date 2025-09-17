//
//  ActivityBackPressedCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class ActivityBackPressedCommand: KeyEventCommand {
    static let id = "activity_back_pressed"
    
    override func toHumanString() -> String {
        localizedString("key_event_action_activity_back_pressed")
    }
}
