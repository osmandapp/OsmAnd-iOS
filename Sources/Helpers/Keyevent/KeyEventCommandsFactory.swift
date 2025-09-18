//
//  KeyEventCommandsFactory.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 03.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyEventCommandsFactory {
    func createCommand(_ commandId: String) -> KeyEventCommand? {
        switch commandId {
        case MapZoomCommand.zoomInId:
            return MapZoomCommand(commandId: commandId, increment: true)
        default:
            return nil
        }
    }
}
