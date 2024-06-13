//
//  CompassVisibility.swift
//  OsmAnd Maps
//
//  Created by Skalii on 27.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objc
enum CompassVisibility: Int32, CaseIterable {

    case alwaysVisible
    case alwaysHidden
    case visibleIfMapRotated

    var title: String {
        switch self {
        case .alwaysVisible: localizedString("compass_always_visible")
        case .alwaysHidden: localizedString("compass_always_hidden")
        case .visibleIfMapRotated: localizedString("compass_visible_if_map_rotated")
        }
    }
    
    var desc: String {
        switch self {
        case .visibleIfMapRotated: localizedString("compass_visible_in_rotated_mode_descr")
        default: ""
        }
    }
    
    var iconName: String {
        switch self {
        case .alwaysVisible: "ic_custom_compass_north"
        case .alwaysHidden: "ic_custom_compass_hidden"
        case .visibleIfMapRotated: "ic_custom_compass_rotated"
        }
    }
}

@objcMembers
final class CompassVisibilityWrapper: NSObject {

    static func getTitleFor(type: CompassVisibility) -> String {
        type.title
    }

    static func getDescFor(type: CompassVisibility) -> String {
        type.desc
    }

    static func getIconNameFor(type: CompassVisibility) -> String {
        type.iconName
    }

    static func getTitles() -> [String] {
        CompassVisibility.allCases.map { $0.title }
    }

    static func getDescs() -> [String] {
        CompassVisibility.allCases.map { $0.desc }
    }

    static func getIconNames() -> [String] {
        CompassVisibility.allCases.map { $0.iconName }
    }
}
