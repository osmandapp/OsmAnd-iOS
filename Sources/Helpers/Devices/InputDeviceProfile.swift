//
//  InputDeviceProfile.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 02.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
class InputDeviceProfile: NSObject {
    var assignmentsCollection: KeyAssignmentsCollection?
    
    func setAssignments(_ assignments: [KeyAssignment]) {
        assignmentsCollection = KeyAssignmentsCollection(assignments)
    }
    
    func filledAssignments() -> [KeyAssignment] {
        assignmentsCollection?.storedAssignments().filter { $0.hasRequiredParameters() } ?? []
    }
    
    func assignments() -> [KeyAssignment] {
        assignmentsCollection?.storedAssignments() ?? []
    }
    
    func assignmentsCopy() -> [KeyAssignment] {
        assignmentsCollection?.assignmentsCopy() ?? []
    }
    
    func hasAssignmentNameDuplicate(with newName: String) -> Bool {
        assignmentsCollection?.hasNameDuplicate(with: newName) ?? false
    }
    
    func findAction(with keyCode: UIKeyboardHIDUsage) -> OAQuickAction? {
        assignmentsCollection?.findByKeyCode(keyCode)?.storedAction()
    }
    
    func findAssignment(by assignmentId: String) -> KeyAssignment? {
        assignmentsCollection?.findById(assignmentId)
    }
    
    func id() -> String {
        fatalError("id() not implemented")
    }
    
    func isCustom() -> Bool {
        false
    }
    
    func toHumanString() -> String {
        fatalError("toHumanString() not implemented")
    }
}
