//
//  WunderLINQDeviceProfile.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 02.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class WunderLINQDeviceProfile: PredefinedInputDeviceProfile {
    static let deviceId = "wunderlinq"
    
    override func collectAssignments() -> [KeyAssignment] {
        var list: [KeyAssignment] = []
        addAssignment(to: &list, with: KeyEventCommand.mapZoomIn.rawValue, keyCodes: [.keyboardUpArrow])
        addAssignment(to: &list, with: KeyEventCommand.mapZoomOut.rawValue, keyCodes: [.keyboardDownArrow])
        addAssignment(to: &list, with: KeyEventCommand.openWunderLINQDatagrid.rawValue, keyCodes: [.keyboardEscape])
        return list
    }
    
    override func id() -> String {
        Self.deviceId
    }
    
    override func toHumanString() -> String {
        localizedString("sett_wunderlinq_ext_input")
    }
}
