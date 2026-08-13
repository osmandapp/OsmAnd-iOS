//
//  ScreenElementsMode.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 13.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objc
enum ScreenElementsMode: Int32, CaseIterable {
    case shared
    case independent
    
    static let defaultMode: ScreenElementsMode = .shared

    var title: String {
        switch self {
        case .shared:
            localizedString("screen_elements_shared")
        case .independent:
            localizedString("screen_elements_independent")
        }
    }

    var usesSeparateLayouts: Bool {
        self == .independent
    }

    init(usesSeparateLayouts: Bool) {
        self = usesSeparateLayouts ? .independent : .shared
    }
}
