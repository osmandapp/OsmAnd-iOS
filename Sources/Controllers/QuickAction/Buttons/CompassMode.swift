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

    var key: String {
        switch self {
        case .manuallyRotated: "MANUALLY_ROTATED"
        case .movementDirection: "MOVEMENT_DIRECTION"
        case .compassDirection: "COMPASS_DIRECTION"
        case .northIsUp: "NORTH_IS_UP"
        }
    }

    func next() -> CompassMode {
        let all = Self.allCases
        if let idx = all.firstIndex(of: self) {
            let nextIdx = (idx + 1) % all.count
            return all[nextIdx]
        }
        return .northIsUp
    }

    static func getByValue(_ value: Int) -> CompassMode {
        for mode in Self.allCases {
            if mode.value == value {
                return mode
            }
        }
        return .northIsUp
    }

    static func getMode(forKey key: String?) -> CompassMode? {
        guard let key = key else { return nil }
        return Self.allCases.first { $0.key == key }
    }
}

@objcMembers
final class CompassModeWrapper: NSObject {
    static func getKeyFor(value: Int) -> String {
        CompassMode.getByValue(value).key
    }
    
    static func getTitleFor(value: Int) -> String {
        CompassMode.getByValue(value).title
    }

    static func getIconNameFor(value: Int) -> String {
        CompassMode.getByValue(value).iconName
    }
    
    static func getTitleFor(key: String) -> String {
        CompassMode.getMode(forKey: key)?.title ?? ""
    }

    static func getIconNameFor(key: String) -> String {
        CompassMode.getMode(forKey: key)?.iconName ?? ""
    }
    
    static func getValueFor(key: String) -> Int {
        CompassMode.getMode(forKey: key)?.value ?? CompassMode.northIsUp.value
    }
    
    static func getAllValues() -> [Int] {
        CompassMode.allCases.map(\.value)
    }
}
