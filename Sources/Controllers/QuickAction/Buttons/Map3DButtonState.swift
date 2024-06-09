//
//  Map3DButtonState.swift
//  OsmAnd Maps
//
//  Created by Skalii on 27.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAMap3DButtonState)
@objcMembers
class Map3DButtonState: MapButtonState {

    static let map3DHudId = "map_3d"

    let visibilityPref: OACommonInteger
    let fabMarginPref: FabMarginPreference
    var elevationAngle = kDefaultElevationAngle

    init() {
        fabMarginPref = FabMarginPreference("map_3d_mode_margin")
        visibilityPref = OAAppSettings.sharedManager().registerIntPreference("map_3d_mode_visibility", defValue: Map3DModeVisibility.visible.rawValue)
        super.init(withId: Self.map3DHudId)
    }

    override func getName() -> String {
        return localizedString("map_3d_mode_action")
    }

    override func isEnabled() -> Bool {
        return getVisibility() != .hidden
    }

    override func getIcon() -> UIImage? {
        return UIImage.templateImageNamed(getVisibility().iconName)
    }

    func getVisibility() -> Map3DModeVisibility {
        Map3DModeVisibility(rawValue: visibilityPref.get())!
    }

    func getVisibility(_ mode: OAApplicationMode) -> Map3DModeVisibility {
        Map3DModeVisibility(rawValue: visibilityPref.get(mode))!
    }
}
