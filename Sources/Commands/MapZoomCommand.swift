//
//  MapZoomCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 03.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class MapZoomCommand: KeyEventCommand {
    static let zoomInId = "zoom_in"
    static let zoomOutId = "zoom_out"
    
    private let increment: Bool
    
    init(commandId: String, increment: Bool) {
        self.increment = increment
        super.init(commandId: commandId)
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        increment ? OARootViewController.instance().mapPanel.mapViewController.zoomIn() : OARootViewController.instance().mapPanel.mapViewController.zoomOut()
    }
    
    override func toHumanString() -> String {
        localizedString(increment ? "key_event_action_zoom_in" : "key_event_action_zoom_out")
    }
}
