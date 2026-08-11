//
//  PanelsLayoutMode.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 11.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

enum PanelsLayoutMode {
    case wide
    case compact

    var title: String {
        switch self {
        case .wide:
            localizedString("panels_layout_wide")
        case .compact:
            localizedString("panels_layout_compact")
        }
    }

    func iconName(for screenLayoutMode: ScreenLayoutMode) -> String {
        switch (screenLayoutMode, self) {
        case (.portrait, .wide):
            "ic_custom_panels_layout_portrait_wide"
        case (.portrait, .compact):
            "ic_custom_panels_layout_portrait_compact"
        case (.landscape, .wide):
            "ic_custom_panels_layout_landscape_wide"
        case (.landscape, .compact):
            "ic_custom_panels_layout_landscape_compact"
        }
    }

    static var defaultMode: PanelsLayoutMode {
        .wide
    }
}
