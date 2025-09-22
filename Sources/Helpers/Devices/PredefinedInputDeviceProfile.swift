//
//  PredefinedInputDeviceProfile.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 02.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class PredefinedInputDeviceProfile: InputDeviceProfile {
    override init() {
        super.init()
        setAssignments(collectAssignments())
    }
    
    func collectAssignments() -> [KeyAssignment] {
        fatalError("collectAssignments() not implemented")
    }
    
    func addAssignment(to assignments: inout [KeyAssignment], with commandId: String, keyCodes: [UIKeyboardHIDUsage]) {
        assignments.append(KeyAssignment(commandId: commandId, keyCodes: keyCodes))
    }
}
