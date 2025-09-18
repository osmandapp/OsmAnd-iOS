//
//  BackToLocationCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class BackToLocationCommand: KeyEventCommand {
    static let id = "back_to_location"
    
    override func toHumanString() -> String {
        localizedString("key_event_action_move_to_my_location")
    }
}
