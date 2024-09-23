//
//  DayNightMode.swift
//  OsmAnd Maps
//
//  Created by Skalii on 20.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc
enum DayNightMode: Int32, CaseIterable {

    case day
    case night
    case auto
    // todo: compatibility with Android, 3 - light sensor
    case appTheme = 4

    var title: String {
        switch self {
        case .day: localizedString("day")
        case .night: localizedString("daynight_mode_night")
        case .auto: localizedString("daynight_mode_auto")
        case .appTheme: localizedString("settings_app_theme")
        }
    }

    var desc: String {
        switch self {
        case .day: localizedString("daynight_mode_day_summary")
        case .night: localizedString("daynight_mode_night_summary")
        case .auto: localizedString("daynight_mode_sunrise_sunset_summary")
        case .appTheme: localizedString("daynight_mode_app_theme_summary")
        }
    }

    var iconName: String {
        switch self {
        case .day: "ic_custom_sun_outlined"
        case .night: "ic_custom_moon_outlined"
        case .auto: "ic_custom_sunset_outlined"
        case .appTheme: "ic_custom_map_mode_app_theme"
        }
    }

    var selectedIconName: String {
        switch self {
        case .day: "ic_custom_sun"
        case .night: "ic_custom_moon"
        case .auto: "ic_custom_sunset"
        case .appTheme: "ic_custom_map_mode_app_theme_filled"
        }
    }
}

@objcMembers
final class DayNightModeWrapper: NSObject {

    static func getTitleFor(type: DayNightMode) -> String {
        type.title
    }

    static func getDescFor(type: DayNightMode) -> String {
        type.desc
    }

    static func getIconNameFor(type: DayNightMode) -> String {
        type.iconName
    }

    static func getSelectedIconNameFor(type: DayNightMode) -> String {
        type.selectedIconName
    }

    static func getTitles() -> [String] {
        DayNightMode.allCases.map { $0.title }
    }

    static func getDescs() -> [String] {
        DayNightMode.allCases.map { $0.desc }
    }

    static func getIconNames() -> [String] {
        DayNightMode.allCases.map { $0.iconName }
    }

    static func getSelectedIconNames() -> [String] {
        DayNightMode.allCases.map { $0.selectedIconName }
    }
}
