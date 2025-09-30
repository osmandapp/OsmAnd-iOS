//
//  KeyEventHandler.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 19.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class KeyEventHelper: UIResponder {
    static let shared = KeyEventHelper()
    
    private let settings: OAAppSettings
    private let deviceHelper: InputDevicesHelper
    
    override init() {
        settings = OAAppSettings.sharedManager()
        deviceHelper = InputDevicesHelper.shared
        super.init()
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key, let action = findAction(with: key.keyCode), let event else { continue }
            action.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key, let action = findAction(with: key.keyCode), let event else { continue }
            action.pressesEnded(presses, with: event)
        }
    }
    
    private func findAction(with keyCode: UIKeyboardHIDUsage) -> OAQuickAction? {
        if isLetterForbid(with: keyCode) {
            return nil
        }
        let appMode = settings.applicationMode.get()
        return deviceHelper.functionalityDevice(with: appMode).findAction(with: keyCode)
    }
    
    private func isLetterForbid(with keyCode: UIKeyboardHIDUsage) -> Bool {
        guard let mapPanel = OARootViewController.instance().mapPanel else { return true }
        let isMapVisible = mapPanel.view.window != nil
        && mapPanel.presentedViewController == nil
        && !mapPanel.isDashboardVisible()
        && !mapPanel.isRouteInfoVisible()
        && !mapPanel.isContextMenuVisible()
        return isLetterKeyCode(keyCode) && !isMapVisible
    }
    
    private func isLetterKeyCode(_ keyCode: UIKeyboardHIDUsage) -> Bool {
        (UIKeyboardHIDUsage.keyboardA.rawValue...UIKeyboardHIDUsage.keyboardZ.rawValue).contains(keyCode.rawValue)
    }
}
