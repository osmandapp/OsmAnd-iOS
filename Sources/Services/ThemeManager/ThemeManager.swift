//
//  ThemeManager.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 06.10.2023.
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
    // 1) kSelectedThemeKey" -  в константу
    // 2) заменить UserDefaults на османд подход
    var currentTheme: Theme {
        if let storedTheme = (UserDefaults.standard.value(forKey: "kSelectedThemeKey") as AnyObject).integerValue {
            return Theme(rawValue: storedTheme)!
        } else {
            return .dark
        }
    }
    
    func configure(appMode: OAApplicationMode) {
        apply(currentTheme, appMode: appMode)
    }

    func apply(_ theme: Theme,
               appMode: OAApplicationMode,
               withNotification: Bool = false) {
        UIWindow.key.overrideUserInterfaceStyle = theme.overrideUserInterfaceStyle
        if withNotification {
            NotificationCenter.default.post(name: .ThemeDidChange, object: self)
        }
    }
}

