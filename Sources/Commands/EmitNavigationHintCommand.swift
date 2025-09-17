//
//  EmitNavigationHintCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class EmitNavigationHintCommand: KeyEventCommand {
    static let id = "emit_navigation_hint"
    
    override func toHumanString() -> String {
        localizedString("key_event_action_emit_navigation_hint")
    }
}
