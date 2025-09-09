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
        guard let id = assignment.getId() else { return }
        assignments.append(assignment)
        assignmentById[id] = assignment
        for code in assignment.getKeyCodes() {
            assignmentByKeyCode[code] = assignment
        }
    }
    
    func getAssignments() -> [KeyAssignment] {
        assignments
    }
    
    func getAssignmentsCopy() -> [KeyAssignment] {
        assignments.map(KeyAssignment.init)
    }
    
    func hasNameDuplicate(with newName: String) -> Bool {
        assignments.contains { $0.getName() == newName }
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
        for a in assignments {
            guard let id = a.getId() else { continue }
            byId[id] = a
            for code in a.getKeyCodes() {
                byKey[code] = a
            }
        }
        assignmentById = byId
        assignmentByKeyCode = byKey
    }
}
