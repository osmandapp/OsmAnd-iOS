//
//  CompassMode.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 11.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc
enum CompassMode: Int32, CaseIterable {
    case manuallyRotated
    case movementDirection
    case compassDirection
    case northIsUp

    var value: Int {
        switch self {
        case .manuallyRotated: ROTATE_MAP_MANUAL
        case .movementDirection: ROTATE_MAP_BEARING
        case .compassDirection: ROTATE_MAP_COMPASS
        case .northIsUp: ROTATE_MAP_NONE
        }
    }

    var title: String {
        switch self {
        case .manuallyRotated: localizedString("rotate_map_manual_opt")
        case .movementDirection: localizedString("rotate_map_bearing_opt")
        case .compassDirection: localizedString("rotate_map_compass_opt")
        case .northIsUp: localizedString("rotate_map_north_opt")
        }
    }

    var iconName: String {
        switch self {
        case .manuallyRotated: "ic_custom_direction_manual_day"
        case .movementDirection: "ic_custom_direction_bearing_day"
        case .compassDirection: "ic_custom_direction_compass_day"
        case .northIsUp: "ic_custom_direction_north_day"
        }
    }
    
    var nightModeIconName: String {
        switch self {
        case .manuallyRotated: "ic_custom_direction_manual_night"
        case .movementDirection: "ic_custom_direction_bearing_night"
        case .compassDirection: "ic_custom_direction_compass_night"
        case .northIsUp: "ic_custom_direction_north_night"
        }
    }

    var key: String {
        switch self {
        case .manuallyRotated: "MANUALLY_ROTATED"
        case .movementDirection: "MOVEMENT_DIRECTION"
        case .compassDirection: "COMPASS_DIRECTION"
        case .northIsUp: "NORTH_IS_UP"
        }
    }

    static func byValue(_ value: Int) -> CompassMode {
        Self.allCases.first { $0.value == value } ?? .northIsUp
    }

    static func mode(forKey key: String?) -> CompassMode? {
        Self.allCases.first { $0.key == key }
    }
}

@objcMembers
final class CompassModeWrapper: NSObject {
    static func key(forValue value: Int) -> String {
        CompassMode.byValue(value).key
    }
    
    static func title(forValue value: Int) -> String {
        CompassMode.byValue(value).title
    }

    static func iconName(forValue value: Int, isNightMode: Bool) -> String {
        let compassMode = CompassMode.byValue(value)
        return isNightMode ? compassMode.nightModeIconName : compassMode.iconName
    }
    
    static func title(forKey key: String) -> String {
        CompassMode.mode(forKey: key)?.title ?? ""
    }

    static func iconName(forKey key: String, isNightMode: Bool) -> String {
        guard let compassMode = CompassMode.mode(forKey: key) else { return "" }
        return isNightMode ? compassMode.nightModeIconName : compassMode.iconName
    }
    
    static func value(for key: String) -> Int {
        CompassMode.mode(forKey: key)?.value ?? CompassMode.northIsUp.value
    }
    
    static func valueCount() -> Int {
        CompassMode.allCases.map(\.value).count
    }
}
