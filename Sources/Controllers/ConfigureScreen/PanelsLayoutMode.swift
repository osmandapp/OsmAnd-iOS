//
//  PanelsLayoutMode.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 11.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objc
enum PanelsLayoutMode: Int32, CaseIterable {
    case wide
    case compact
    
    static let defaultMode: PanelsLayoutMode = .wide

    var title: String {
        switch self {
        case .wide:
            localizedString("panels_layout_wide")
        case .compact:
            localizedString("panels_layout_compact")
        }
    }

    var description: String {
        switch self {
        case .wide:
            localizedString("panels_layout_wide_descr")
        case .compact:
            localizedString("panels_layout_compact_descr")
        }
    }

    var key: String {
        switch self {
        case .wide: "WIDE"
        case .compact: "COMPACT"
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

    func imageName(for screenLayoutMode: ScreenLayoutMode) -> String {
        switch (screenLayoutMode, self) {
        case (.portrait, .wide):
            "img_panels_layout_portrait_wide"
        case (.portrait, .compact):
            "img_panels_layout_portrait_compact"
        case (.landscape, .wide):
            "img_panels_layout_landscape_wide"
        case (.landscape, .compact):
            "img_panels_layout_landscape_compact"
        }
    }
}
