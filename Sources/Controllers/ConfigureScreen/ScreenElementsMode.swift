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

    var key: String {
        switch self {
        case .shared: "single"
        case .independent: "separate"
        }
    }

    init(usesSeparateLayouts: Bool) {
        self = usesSeparateLayouts ? .independent : .shared
    }
}

@objcMembers
final class ScreenElementsModeWrapper: NSObject {
    static func key(for mode: ScreenElementsMode) -> String {
        mode.key
    }

    static func allValues() -> [NSNumber] {
        ScreenElementsMode.allCases.map { NSNumber(value: $0.rawValue) }
    }
}
