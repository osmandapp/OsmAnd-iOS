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
        addAssignment(to: &list, with: BackToLocationCommand.id, keyCodes: [.keyboardC])
        addAssignment(to: &list, with: SwitchCompassCommand.id, keyCodes: [.keyboardD])
        addAssignment(to: &list, with: OpenNavigationDialogCommand.id, keyCodes: [.keyboardN])
        addAssignment(to: &list, with: OpenQuickSearchDialogCommand.id, keyCodes: [.keyboardS])
        addAssignment(to: &list, with: SwitchAppModeCommand.switchToNextId, keyCodes: [.keyboardP])
        addAssignment(to: &list, with: SwitchAppModeCommand.switchToPreviusId, keyCodes: [.keyboardO])
        
        addAssignment(to: &list, with: MapScrollCommand.scrollUpId, keyCodes: [.keyboardUpArrow])
        addAssignment(to: &list, with: MapScrollCommand.scrollDownId, keyCodes: [.keyboardDownArrow])
        addAssignment(to: &list, with: MapScrollCommand.scrollLeftId, keyCodes: [.keyboardLeftArrow])
        addAssignment(to: &list, with: MapScrollCommand.scrollRightId, keyCodes: [.keyboardRightArrow])
        
        addAssignment(to: &list, with: MapZoomCommand.zoomInId, keyCodes: [.keypadPlus, .keyboardEqualSign])
        addAssignment(to: &list, with: MapZoomCommand.zoomOutId, keyCodes: [.keyboardHyphen])
        
        addAssignment(to: &list, with: ToggleDrawerCommand.id, keyCodes: [.keyboardM])
        addAssignment(to: &list, with: ActivityBackPressedCommand.id, keyCodes: [.keyboardEscape, .keyboardDeleteOrBackspace])
        return list
    }
    
    override func getId() -> String {
        Self.deviceId
    }
    
    override func toHumanString() -> String {
        localizedString("sett_generic_ext_input")
    }
}
