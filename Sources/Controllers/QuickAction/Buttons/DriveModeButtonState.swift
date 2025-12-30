//
//  DriveModeButtonState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class DriveModeButtonState: SwitchVisibilityMapButtonState {
    static let hudId = "map.view.route_planning"
    
    lazy var visibilityPref: OACommonBoolean = OAAppSettings.sharedManager().registerBooleanPreference("\(id)_state", defValue: true)
    
    init() {
        super.init(withId: Self.hudId)
    }
    
    override func getName() -> String {
        localizedString("shared_string_navigation")
    }
    
    override func defaultIconName() -> String {
        OARoutingHelper.sharedInstance().isFollowingMode() ? "ic_custom_navigation_arrow" : "ic_custom_navigation"
    }
    
    override func buttonDescription() -> String {
        localizedString("navigation_action_descr")
    }
    
    override func isEnabled() -> Bool {
        visibilityPref.get()
    }
    
    @discardableResult override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.companion.POS_LEFT, posV: ButtonPositionSize.companion.POS_BOTTOM, xMove: true, yMove: false)
    }
    
    override func storedVisibilityPref() -> OACommonBoolean {
        visibilityPref
    }
}
