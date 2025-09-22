//
//  KeyboardDeviceProfile.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 02.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class KeyboardDeviceProfile: PredefinedInputDeviceProfile {
    static let deviceId = "keyboard"
    
    override func collectAssignments() -> [KeyAssignment] {
        var list: [KeyAssignment] = []
        addAssignment(to: &list, with: KeyEventCommand.backToLocation.rawValue, keyCodes: [.keyboardC])
        addAssignment(to: &list, with: KeyEventCommand.switchCompass.rawValue, keyCodes: [.keyboardD])
        addAssignment(to: &list, with: KeyEventCommand.openNavigationDialog.rawValue, keyCodes: [.keyboardN])
        addAssignment(to: &list, with: KeyEventCommand.openQuickSearchDialog.rawValue, keyCodes: [.keyboardS])
        addAssignment(to: &list, with: KeyEventCommand.switchAppModeToNext.rawValue, keyCodes: [.keyboardP])
        addAssignment(to: &list, with: KeyEventCommand.switchAppModeToPrevius.rawValue, keyCodes: [.keyboardO])
        
        addAssignment(to: &list, with: KeyEventCommand.mapScrollUp.rawValue, keyCodes: [.keyboardUpArrow])
        addAssignment(to: &list, with: KeyEventCommand.mapScrollDown.rawValue, keyCodes: [.keyboardDownArrow])
        addAssignment(to: &list, with: KeyEventCommand.mapScrollLeft.rawValue, keyCodes: [.keyboardLeftArrow])
        addAssignment(to: &list, with: KeyEventCommand.mapScrollRight.rawValue, keyCodes: [.keyboardRightArrow])
        
        addAssignment(to: &list, with: KeyEventCommand.mapZoomIn.rawValue, keyCodes: [.keypadPlus, .keyboardEqualSign])
        addAssignment(to: &list, with: KeyEventCommand.mapZoomOut.rawValue, keyCodes: [.keyboardHyphen])
        
        addAssignment(to: &list, with: KeyEventCommand.toggleDrawer.rawValue, keyCodes: [.keyboardM])
        addAssignment(to: &list, with: KeyEventCommand.activityBackPressed.rawValue, keyCodes: [.keyboardEscape, .keyboardDeleteOrBackspace])
        return list
    }
    
    override func id() -> String {
        Self.deviceId
    }
    
    override func toHumanString() -> String {
        localizedString("sett_generic_ext_input")
    }
}
