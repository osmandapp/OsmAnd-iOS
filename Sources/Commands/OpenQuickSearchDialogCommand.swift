//
//  OpenQuickSearchDialogCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class OpenQuickSearchDialogCommand: KeyEventCommand {
    static let id = "open_quick_search_dialog"
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        OARootViewController.instance().mapPanel.open(.REGULAR)
    }
    
    override func toHumanString() -> String {
        localizedString("key_event_action_open_search_view")
    }
}
