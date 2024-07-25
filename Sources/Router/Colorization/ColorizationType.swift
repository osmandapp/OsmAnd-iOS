//
//  ColorizationType.swift
//  OsmAnd Maps
//
//  Created by Skalii on 17.07.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc enum ColorizationType: Int {
    case elevation
    case speed
    case slope
    case none

    var name: String {
        switch self {
        case .elevation: "elevation"
        case .speed: "speed"
        case .slope: "slope"
        case .none: "none"
        }
    }
}
