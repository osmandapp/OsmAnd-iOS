//
//  Map3DButtonState.swift
//  OsmAnd Maps
//
//  Created by Skalii on 27.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class Map3DButtonState: MapButtonState {

    static let map3DHudId = "map.view.map_3d"

    let visibilityPref: OACommonInteger
    let fabMarginPref: FabMarginPreference
    var elevationAngle = kDefaultElevationAngle

    init() {
        fabMarginPref = FabMarginPreference("map_3d_mode_margin")
        visibilityPref = OAAppSettings.sharedManager().registerIntPreference("map_3d_mode_visibility", defValue: Map3DModeVisibility.visible.rawValue)
        super.init(withId: Self.map3DHudId)
    }

    override func getName() -> String {
        localizedString("map_3d_mode_action")
    }

    override func isEnabled() -> Bool {
        getVisibility() != .hidden
    }

    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed(getVisibility().iconName)
    }
    
    override func getPreviewIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_custom_3d")
    }
    
    override func updatePosition(_ position: ButtonPositionSize) {
        position.marginX = Int32(ButtonPositionSize.companion.CELL_SIZE_DP)
        position.marginY = Int32(ButtonPositionSize.companion.CELL_SIZE_DP)
        super.updatePosition(position)
        position.xMove = !portrait
        position.yMove = portrait
    }
    
    override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.companion.POS_RIGHT, posV: ButtonPositionSize.companion.POS_BOTTOM, xMove: true, yMove: true)
    }
    
    override func storedVisibilityPref() -> OACommonInteger {
        visibilityPref
    }
    
    override func copyPrefs(from fromMode: OAApplicationMode, to toMode: OAApplicationMode) {
        visibilityPref.set(getVisibility(fromMode).rawValue, mode: toMode)
    }

    func getVisibility() -> Map3DModeVisibility {
        Map3DModeVisibility(rawValue: visibilityPref.get())!
    }

    func getVisibility(_ mode: OAApplicationMode) -> Map3DModeVisibility {
        Map3DModeVisibility(rawValue: visibilityPref.get(mode))!
    }
}
