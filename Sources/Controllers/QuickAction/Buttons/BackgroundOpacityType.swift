//
//  BackgroundOpacityType.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 09.01.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objc
enum BackgroundOpacityType: Int32 {
    case solid
    case liquidGlass
    
    var title: String {
        switch self {
        case .solid: localizedString("track_coloring_solid")
        case .liquidGlass: localizedString("liquid_glass")
        }
    }
}
