//
//  Map3DModeVisibility.swift
//  OsmAnd Maps
//
//  Created by Skalii on 27.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objc(EOAMap3DModeVisibility)
enum Map3DModeVisibility: Int32, CaseIterable {

    case hidden
    case visible
    case visibleIn3DMode

    var title: String {
        switch self {
        case .hidden: localizedString("shared_string_hidden")
        case .visible: localizedString("shared_string_visible")
        case .visibleIn3DMode: localizedString("visible_in_3d_mode")
        }
    }

    var iconName: String {
        switch self {
        case .hidden: "ic_custom_button_3d_off"
        default: "ic_custom_button_3d"
        }
    }
}

@objc(EOAMap3DModeVisibilityWrapper)
@objcMembers
final class Map3DModeVisibilityWrapper: NSObject {

    static func getTitleFor(type: Map3DModeVisibility) -> String {
        type.title
    }

    static func getIconNameFor(type: Map3DModeVisibility) -> String {
        type.iconName
    }
}
