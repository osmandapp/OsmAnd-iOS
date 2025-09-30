//
//  KeyAssignmentsCollection.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 05.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyAssignmentsCollection {
    private var assignments: [KeyAssignment]
    private var assignmentById: [String: KeyAssignment] = [:]
    private var assignmentByKeyCode: [UIKeyboardHIDUsage: KeyAssignment] = [:]
    
    init(_ assignments: [KeyAssignment]) {
        self.assignments = assignments
        syncCache()
    }
    
    func setAssignments(_ assignments: [KeyAssignment]) {
        self.assignments.removeAll()
        self.assignments.append(contentsOf: assignments)
        syncCache()
    }
    
    func addAssignment(_ assignment: KeyAssignment) {
        guard let id = assignment.storedId() else { return }
        assignments.append(assignment)
        assignmentById[id] = assignment
        assignment.storedKeyCodes().forEach { assignmentByKeyCode[$0] = assignment }
    }
    
    func storedAssignments() -> [KeyAssignment] {
        assignments
    }
    
    func assignmentsCopy() -> [KeyAssignment] {
        assignments.map(KeyAssignment.init)
    }
    
    func hasNameDuplicate(with newName: String) -> Bool {
        assignments.contains { $0.name() == newName }
    }
    
    func findById(_ id: String) -> KeyAssignment? {
        assignmentById[id]
    }
    
    func findByKeyCode(_ keyCode: UIKeyboardHIDUsage) -> KeyAssignment? {
        assignmentByKeyCode[keyCode]
    }
    
    func syncCache() {
        var byId: [String: KeyAssignment] = [:]
        var byKey: [UIKeyboardHIDUsage: KeyAssignment] = [:]
        for assignment in assignments {
            guard let id = assignment.storedId() else { continue }
            byId[id] = assignment
            assignment.storedKeyCodes().forEach { byKey[$0] = assignment }
        }
        assignmentById = byId
        assignmentByKeyCode = byKey
    }
}
