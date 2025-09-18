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
    
    func getFilledAssignments() -> [KeyAssignment] {
        assignmentsCollection?.getAssignments().filter { $0.hasRequiredParameters() } ?? []
    }
    
    func getAssignments() -> [KeyAssignment] {
        assignmentsCollection?.getAssignments() ?? []
    }
    
    func getAssignmentsCopy() -> [KeyAssignment] {
        assignmentsCollection?.getAssignmentsCopy() ?? []
    }
    
    func hasAssignmentNameDuplicate(with newName: String) -> Bool {
        assignmentsCollection?.hasNameDuplicate(with: newName) ?? false
    }
    
    func findAction(with keyCode: UIKeyboardHIDUsage) -> OAQuickAction? {
        findAssignment(with: keyCode)?.getAction()
    }
    
    func findAssignment(with keyCode: UIKeyboardHIDUsage) -> KeyAssignment? {
        assignmentsCollection?.findByKeyCode(keyCode)
    }
    
    func findAssignment(by assignmentId: String) -> KeyAssignment? {
        assignmentsCollection?.findById(assignmentId)
    }
    
    func hasActiveAssignments() -> Bool {
        getFilledAssignmentsCount() > 0
    }
    
    func getFilledAssignmentsCount() -> Int {
        getFilledAssignments().count
    }
    
    func getId() -> String {
        fatalError()
    }
    
    func isCustom() -> Bool {
        false
    }
    
    func toHumanString() -> String {
        fatalError()
    }
}
