//
//  MapSettingsButtonState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MapSettingsButtonState: SwitchVisibilityMapButtonState {
    static let hudId = "map.view.layers"
    
    lazy var visibilityPref: OACommonBoolean = OAAppSettings.sharedManager().registerBooleanPreference("\(id)_state", defValue: true)
    
    init() {
        super.init(withId: Self.hudId)
    }
    
    override func getName() -> String {
        localizedString("configure_map")
    }
    
    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_custom_overlay_map")
    }
    
    override func buttonDescription() -> String {
        localizedString("configure_map_description")
    }
    
    override func isEnabled() -> Bool {
        visibilityPref.get()
    }
    
    @discardableResult override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.companion.POS_LEFT, posV: ButtonPositionSize.companion.POS_TOP, xMove: false, yMove: true)
    }
    
    override func storedVisibilityPref() -> OACommonBoolean {
        visibilityPref
    }
}
