//
//  MarkerDisplayOption.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 04/09/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class MarkerDisplayOptionWrapper: NSObject {
    
    static func allValues() -> [MarkerDisplayOption] {
        return [.off, .resting, .navigation, .restingNavigation]
    }
    
    static func off() -> MarkerDisplayOption {
        .off
    }
    
    static func resting() -> MarkerDisplayOption {
        .resting
    }
    
    static func navigation() -> MarkerDisplayOption {
        .navigation
    }
    
    static func restingNavigation() -> MarkerDisplayOption {
        .restingNavigation
    }
    
    static func value(by index: Int32) -> MarkerDisplayOption {
        MarkerDisplayOption.value(by: index)
    }
    
    static func getNameFor(type: MarkerDisplayOption) -> String {
        type.nameId
    }
    
    static func isVisible(type: MarkerDisplayOption, state: EOAMarkerState) -> Bool {
        type.isVisible(markerState: state)
    }
}

@objc
enum MarkerDisplayOption: Int32, CaseIterable {
    case off, resting, navigation, restingNavigation

    // MARK: - Properties

    var nameId: String {
        switch self {
        case .off:
            return "shared_string_off"
        case .resting:
            return "resting_position"
        case .navigation:
            return "navigation_position"
        case .restingNavigation:
            return "resting_navigation_position"
        }
    }

    var markerStates: [EOAMarkerState] {
        switch self {
        case .off:
            return [.none]
        case .resting:
            return [.stay]
        case .navigation:
            return [.move]
        case .restingNavigation:
            return [.move, .stay]
        }
    }

    // MARK: - Methods

    static func value(by index: Int32) -> MarkerDisplayOption {
        MarkerDisplayOption(rawValue: index) ?? .off
    }

    func name() -> String {
        localizedString(nameId)
    }

    func isVisible(markerState: EOAMarkerState) -> Bool {
        self != .off && markerStates.contains(markerState)
    }
}
