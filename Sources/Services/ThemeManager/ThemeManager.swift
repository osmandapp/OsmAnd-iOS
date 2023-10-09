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
    private override init() {}

    var currentTheme: Theme {
       let appMode = OAAppSettings.sharedManager().applicationMode.get()
       let savedTheme = OAAppSettings.sharedManager().appearanceProfileTheme.get(appMode)
        guard let theme = Theme(rawValue: Int(savedTheme)) else {
            return .system
        }
        return theme
    }
    
    func configure(appMode: OAApplicationMode) {
        let savedTheme = OAAppSettings.sharedManager().appearanceProfileTheme.get(appMode)
        guard let theme = Theme(rawValue: Int(savedTheme)) else {
            return
        }
        UIWindow.key.overrideUserInterfaceStyle = theme.overrideUserInterfaceStyle
    }

    func apply(_ theme: Theme, withNotification: Bool = false) {
        guard currentTheme != theme else {
            return
        }
        UIWindow.key.overrideUserInterfaceStyle = theme.overrideUserInterfaceStyle
        if withNotification {
            NotificationCenter.default.post(name: .ThemeDidChange, object: self)
        }
    }
}

