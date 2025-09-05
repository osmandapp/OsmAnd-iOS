//
//  KeyEventCommandsCache.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 03.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyEventCommandsCache {
    private static var cachedCommands: [String: KeyEventCommand] = [:]
    private static let keyEventCommandsFactory = KeyEventCommandsFactory()
    
    static func getOrCreateCommand(_ commandId: String) -> KeyEventCommand? {
        if let existing = cachedCommands[commandId] {
            return existing
        }
        if let newCommand = keyEventCommandsFactory.createCommand(commandId) {
            cachedCommands[commandId] = newCommand
            return newCommand
        }
        return nil
    }
}
