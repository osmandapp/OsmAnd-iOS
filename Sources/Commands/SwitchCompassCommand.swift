//
//  SwitchCompassCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class SwitchCompassCommand: KeyEventCommand {
    static let id = "switch_compass_forward"
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        OAMapViewTrackingUtilities.instance().switchRotateMapMode()
    }
    
    override func toHumanString() -> String {
        localizedString("key_event_action_change_map_orientation")
    }
}
