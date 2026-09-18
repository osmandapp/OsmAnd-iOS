//
//  PanelsLayoutMode.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 11.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objc enum PanelsLayoutMode: Int32, CaseIterable {
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

    func icon(for screenLayoutMode: ScreenLayoutMode) -> UIImage {
        switch (screenLayoutMode, self) {
        case (.portrait, .wide):
            .icCustomPanelsLayoutPortraitWide
        case (.portrait, .compact):
            .icCustomPanelsLayoutPortraitCompact
        case (.landscape, .wide):
            .icCustomPanelsLayoutLandscapeWide
        case (.landscape, .compact):
            .icCustomPanelsLayoutLandscapeCompact
        }
    }

    func image(for screenLayoutMode: ScreenLayoutMode) -> UIImage {
        switch (screenLayoutMode, self) {
        case (.portrait, .wide):
            .imgPanelsLayoutPortraitWide
        case (.portrait, .compact):
            .imgPanelsLayoutPortraitCompact
        case (.landscape, .wide):
            .imgPanelsLayoutLandscapeWide
        case (.landscape, .compact):
            .imgPanelsLayoutLandscapeCompact
        }
    }
}
