//
//  ScreenLayoutMode.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 10.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objc
enum ScreenLayoutMode: Int32, CaseIterable {
    case portrait
    case landscape

    var title: String {
        switch self {
        case .portrait:
            localizedString("map_orientation_portrait")
        case .landscape:
            localizedString("map_orientation_landscape")
        }
    }

    var isPortrait: Bool {
        self == .portrait
    }
    
    static var defaultMode: ScreenLayoutMode {
        .portrait
    }
}

@objc
enum ScreenElementsMode: Int32, CaseIterable {
    case shared
    case independent
}
