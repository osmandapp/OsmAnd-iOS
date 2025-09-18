//
//  OpenNavigationDialogCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class OpenNavigationDialogCommand: KeyEventCommand {
    static let id = "open_navigation_dialog"
    
    override func toHumanString() -> String {
        localizedString("key_event_action_open_navigation_view")
    }
}
