//
//  SunPositionMode.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 20.02.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc enum SunPositionMode: Int {
    case sunPositionMode
    case sunsetMode
    case sunriseMode
    
    var prefId: String {
        switch self {
        case .sunPositionMode: localizedString("shared_string_next_event")
        case .sunsetMode: localizedString("map_widget_sunset")
        case .sunriseMode: localizedString("map_widget_sunrise")
        }
    }
}
