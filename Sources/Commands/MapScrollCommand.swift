//
//  MapScrollCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class MapScrollCommand: KeyEventCommand {
    static let scrollUpId = "map_scroll_up"
    static let scrollDownId = "map_scroll_down"
    static let scrollLeftId = "map_scroll_left"
    static let scrollRightId = "map_scroll_right"
    
    private let direction: EOAMapPanDirection
    
    init(commandId: String, direction: EOAMapPanDirection) {
        self.direction = direction
        super.init(commandId: commandId)
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        let mapViewController = OARootViewController.instance().mapPanel.mapViewController
        switch direction {
        case .up:
            mapViewController.animatedPanUp()
        case .down:
            mapViewController.animatedPanDown()
        case .left:
            mapViewController.animatedPanLeft()
        case .right:
            mapViewController.animatedPanRight()
        @unknown default:
            return
        }
    }
    
    override func toHumanString() -> String {
        switch direction {
        case .up: localizedString("key_event_action_move_up")
        case .down: localizedString("key_event_action_move_down")
        case .left: localizedString("key_event_action_move_left")
        case .right: localizedString("key_event_action_move_right")
        @unknown default: ""
        }
    }
}
