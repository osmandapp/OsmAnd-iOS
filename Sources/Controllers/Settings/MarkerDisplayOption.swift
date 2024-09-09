//
//  MarkerDisplayOption.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 04/09/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class MarkerDisplayOption: NSObject {
    
    static var off = MarkerDisplayOption(rawValue: 0, nameId: "shared_string_off", markerStates: [.none])
    static var resting = MarkerDisplayOption(rawValue: 1, nameId: "resting_position", markerStates: [.stay])
    static var navigation = MarkerDisplayOption(rawValue: 2, nameId: "navigation_position", markerStates: [.move])
    static var restingNavigation = MarkerDisplayOption(rawValue: 3, nameId: "resting_navigation_position", markerStates: [.move, .stay])
    
    let rawValue: Int32
    let nameId: String
    private let markerStates: [EOAMarkerState]
    
    static func allValues() -> [MarkerDisplayOption] {
        [off, resting, navigation, restingNavigation]
    }
    
    static func valueBy(index: Int32) -> MarkerDisplayOption {
        if index == off.rawValue {
            return off
        } else if index == resting.rawValue {
            return resting
        } else if index == navigation.rawValue {
            return navigation
        } else if index == restingNavigation.rawValue {
            return restingNavigation
        }
        return off
    }
    
    init(rawValue: Int32, nameId: String, markerStates: [EOAMarkerState]) {
        self.rawValue = rawValue
        self.nameId = nameId
        self.markerStates = markerStates
        super.init()
    }
    
    func name() -> String {
        localizedString(nameId)
    }
    
    func isVisible(markerState: EOAMarkerState) -> Bool {
        self != Self.off && markerStates.contains(markerState)
    }
}
