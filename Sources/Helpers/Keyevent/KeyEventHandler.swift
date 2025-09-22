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
        return deviceHelper.getFunctionalityDevice(with: appMode).findAction(with: keyCode)
    }
    
    private func isLetterForbid(with keyCode: UIKeyboardHIDUsage) -> Bool {
        let isMapVisible = OARootViewController.instance().mapPanel.children.last is OAMapillaryImageViewController && !OARouteInfoView.isVisible() && OARootViewController.instance().mapPanel.presentedViewController == nil && OARootViewController.instance().mapPanel.navigationController?.children.count == 1
        return isLetterKeyCode(keyCode) && !isMapVisible
    }
    
    private func isLetterKeyCode(_ keyCode: UIKeyboardHIDUsage) -> Bool {
        (UIKeyboardHIDUsage.keyboardA.rawValue...UIKeyboardHIDUsage.keyboardZ.rawValue).contains(keyCode.rawValue)
    }
}
