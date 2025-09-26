//
//  CustomInputDeviceProfile.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 03.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class CustomInputDeviceProfile: InputDeviceProfile {
    private let customId: String
    private var customName: String
    
    init(customId: String, customName: String, parentDevice: InputDeviceProfile) {
        self.customId = customId
        self.customName = customName
        super.init()
        setAssignments(parentDevice.assignmentsCopy())
    }
    
    init(_ object: [String: Any]) throws {
        guard let id = object["id"] as? String,
              let name = object["name"] as? String else {
            throw NSError(domain: "CustomInputDeviceProfile", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing id or name"])
        }
        customId = id
        customName = name
        super.init()
        
        let jsonArray: [[String: Any]]
        if let assignment = object["assignments"] as? [[String: Any]] {
            jsonArray = assignment
        } else if let assignment = object["keybindings"] as? [[String: Any]] {
            jsonArray = assignment
        } else {
            jsonArray = []
        }
        
        var assignments: [KeyAssignment] = []
        for json in jsonArray {
            let keyAssignment = KeyAssignment(jsonObject: json)
            assignments.append(keyAssignment)
        }
        setAssignments(assignments)
    }
    
    override func id() -> String {
        customId
    }
    
    override func isCustom() -> Bool {
        true
    }
    
    override func toHumanString() -> String {
        customName
    }
    
    func setCustomName(_ customName: String) {
        self.customName = customName
    }
    
    func renameAssignment(_ assignmentId: String, with newName: String) {
        guard let assignment = assignmentsCollection?.findById(assignmentId) else { return }
        assignment.setCustomName(newName)
    }
    
    func addAssignment(_ assignment: KeyAssignment) {
        assignment.storedKeyCodes().forEach { removeKeyCodeFromPreviousAssignment(assignment, with: $0) }
        assignmentsCollection?.addAssignment(assignment)
        assignmentsCollection?.syncCache()
    }
    
    func updateAssignment(_ assignmentId: String, action: OAQuickAction, keyCodes: [UIKeyboardHIDUsage]) {
        guard let assignment = assignmentsCollection?.findById(assignmentId) else { return }
        keyCodes.forEach { removeKeyCodeFromPreviousAssignment(assignment, with: $0) }
        assignment.setAction(action)
        assignment.setKeyCodes(keyCodes)
        assignmentsCollection?.syncCache()
    }
    
    func removeKeyAssignmentCompletely(by assignmentId: String) {
        guard let previousAssignment = assignmentsCollection?.findById(assignmentId), var list = assignmentsCollection?.storedAssignments() else { return }
        
        if let idx = list.firstIndex(where: { $0.storedId() == previousAssignment.storedId() }) {
            list.remove(at: idx)
            assignmentsCollection?.setAssignments(list)
            assignmentsCollection?.syncCache()
        }
    }
    
    func saveUpdatedAssignmentsList(_ assignments: [KeyAssignment]) {
        assignmentsCollection?.setAssignments(assignments)
        assignmentsCollection?.syncCache()
    }

    func clearAllAssignments() {
        assignmentsCollection?.setAssignments([])
        assignmentsCollection?.syncCache()
    }
    
    func toJson() -> [String: Any] {
        var jsonObject: [String: Any] = [:]
        jsonObject["id"] = customId
        jsonObject["name"] = customName
        
        var jsonArray: [[String: Any]] = []
        assignments().forEach { jsonArray.append($0.toJson()) }
        jsonObject["assignments"] = jsonArray
        
        return jsonObject
    }
    
    private func removeKeyCodeFromPreviousAssignment(_ assignment: KeyAssignment, with keyCode: UIKeyboardHIDUsage) {
        guard let previous = assignmentsCollection?.findByKeyCode(keyCode) else { return }
        previous.removeKeyCode(keyCode)
        if let id = previous.storedId(), assignment.storedId() != previous.storedId() && !previous.hasKeyCodes() {
            removeKeyAssignmentCompletely(by: id)
        }
    }
}
