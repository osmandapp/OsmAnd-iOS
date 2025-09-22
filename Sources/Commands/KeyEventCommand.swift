//
//  KeyEventCommand.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 03.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class KeyEventCommand: UIResponder {
    private let commandId: String
    
    init(commandId: String) {
        self.commandId = commandId
    }
    
    func getId() -> String {
        commandId
    }
    
    func toHumanString() -> String {
        fatalError()
    }
}
