//
//  KeyAssignment.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyAssignment {
    private static var idCounter = 0
    
    private var id: String?
    private var commandId: String?
    private var customName: String?
    private var action: OAQuickAction?
    private var inputs: [String] = []
    
    init(action: OAQuickAction?, inputs: [String]) {
        self.id = Self.generateUniqueId()
        self.action = action
        self.inputs = inputs
    }
    
    init(original: KeyAssignment) {
        self.id = original.id
        self.action = original.action
        self.commandId = original.commandId
        self.customName = original.customName
        self.inputs = original.inputs
    }
    
    init(action: OAQuickAction) {
        self.action = action
    }
    
    init(inputs: [String]) {
        self.inputs = inputs
    }
    
    convenience init(commandId: String, inputs: String...) {
        self.init(action: CommandToActionConverter.createQuickAction(with: commandId), inputs: inputs)
        self.commandId = commandId
    }
    
    func removeInput(_ input: String) {
        guard let index = inputs.firstIndex(of: input) else { return }
        inputs.remove(at: index)
    }
    
    func getId() -> String? {
        id
    }
    
    func getName() -> String? {
        guard let customName else { return getDefaultName() }
        return customName
    }

    func getDefaultName() -> String? {
        guard let action else { return commandId }
        return action.getExtendedName()
    }
    
    func setCustomName(_ customName: String) {
        self.customName = customName
    }

    func getAction() -> OAQuickAction? {
        action
    }
    
    func hasInputs() -> Bool {
        !getInputs().isEmpty
    }
    
    func hasRequiredParameters() -> Bool {
        hasInputs() && action != nil
    }
    
    func getInputs() -> [String] {
        inputs
    }
    
    func getIcon() -> String? {
        guard let action else { return "ic_action_info_outlined" }
        return action.getIconResName()
    }
    
    private static func generateUniqueId() -> String {
        idCounter += 1
        return "key_assignment_\(Date().timeIntervalSince1970 * 1000)_\(idCounter)"
    }
}
