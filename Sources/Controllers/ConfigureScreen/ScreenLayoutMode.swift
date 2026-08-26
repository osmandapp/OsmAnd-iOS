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

    static func `default`(forAppMode appMode: OAApplicationMode) -> ScreenLayoutMode {
        OAAppSettings.sharedManager().useSeparateLayouts.get(appMode) && OAUtilities.isLandscape()
            ? .landscape
            : .portrait
    }
    
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

    var key: String {
        switch self {
        case .portrait: "portrait"
        case .landscape: "landscape"
        }
    }
}

@objcMembers
final class ScreenLayoutModeWrapper: NSObject {
    static func `default`(forAppMode appMode: OAApplicationMode) -> ScreenLayoutMode {
        ScreenLayoutMode.default(forAppMode: appMode)
    }

    static func key(for mode: ScreenLayoutMode) -> String {
        mode.key
    }

    static func allValues() -> [NSNumber] {
        ScreenLayoutMode.allCases.map { NSNumber(value: $0.rawValue) }
    }
}
