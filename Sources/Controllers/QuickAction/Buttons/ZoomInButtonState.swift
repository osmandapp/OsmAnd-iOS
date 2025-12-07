//
//  ZoomInButtonState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ZoomInButtonState: SwitchVisibilityMapButtonState {
    static let hudId = "map.view.zoom_id"
    
    lazy var visibilityPref: OACommonBoolean = OAAppSettings.sharedManager().registerBooleanPreference("\(id)_state", defValue: true)
    
    init() {
        super.init(withId: Self.hudId)
    }
    
    override func getName() -> String {
        localizedString("key_hint_zoom_in")
    }
    
    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_custom_map_zoom_in")
    }
    
    override func isEnabled() -> Bool {
        visibilityPref.get()
    }
    
    @discardableResult override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.companion.POS_RIGHT, posV: ButtonPositionSize.companion.POS_BOTTOM, xMove: false, yMove: true)
    }
    
    override func storedVisibilityPref() -> OACommonBoolean {
        visibilityPref
    }
}
