//
//  ThemeManager.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let ThemeDidChange = Notification.Name("ThemeDidChangeNotification")
}

@objcMembers
final class ThemeManager: NSObject {
    static let shared = ThemeManager()
    
    var currentTheme: Theme {
        let appMode = OAAppSettings.sharedManager().currentMode
        let savedTheme = OAAppSettings.sharedManager().appearanceProfileTheme.get(appMode)
        guard let theme = Theme(rawValue: Int(savedTheme)) else {
            return .system
        }
        return theme
    }
    
    private override init() {}
    
    func configure(appMode: OAApplicationMode) {
        let savedTheme = OAAppSettings.sharedManager().appearanceProfileTheme.get(appMode)
        guard let theme = Theme(rawValue: Int(savedTheme)) else {
            fatalError("theme rawValue is wrong")
        }
        overrideUserInterfaceStyle(theme)
    }

    func apply(_ theme: Theme, appMode: OAApplicationMode, withNotification: Bool = false) {
        guard Theme(rawValue: Int(OAAppSettings.sharedManager()!.appearanceProfileTheme.get(appMode))) != theme else {
            return
        }
        let currentAppMode = OAAppSettings.sharedManager().currentMode
        OAAppSettings.sharedManager().appearanceProfileTheme.set(Int32(theme.rawValue), mode: appMode)
        if appMode == currentAppMode {
            overrideUserInterfaceStyle(theme)
        }
        if withNotification {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .ThemeDidChange, object: self)
            }
        }
    }
    
    func isLightTheme() -> Bool {
        switch currentTheme {
        case .light:
            return true
        case .dark:
            return false
        case .system:
            return UIScreen.main.traitCollection.userInterfaceStyle != .dark
        }
    }
    
    private func overrideUserInterfaceStyle(_ theme: Theme) {
        DispatchQueue.main.async {
            UIApplication.shared.mainWindow?.overrideUserInterfaceStyle = theme.overrideUserInterfaceStyle
        }
    }
}
