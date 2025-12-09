//
//  MyLocationButtonState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MyLocationButtonState: SwitchVisibilityMapButtonState {
    static let hudId = "map.view.back_to_loc"
    
    lazy var visibilityPref: OACommonBoolean = OAAppSettings.sharedManager().registerBooleanPreference("\(id)_state", defValue: true)
    
    init() {
        super.init(withId: Self.hudId)
    }
    
    override func getName() -> String {
        localizedString("shared_string_my_location")
    }
    
    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_custom_map_location_position")
    }
    
    override func buttonDescription() -> String {
        localizedString("my_location_action_descr")
    }
    
    override func isEnabled() -> Bool {
        visibilityPref.get()
    }
    
    @discardableResult override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.companion.POS_RIGHT, posV: ButtonPositionSize.companion.POS_BOTTOM, xMove: true, yMove: false)
    }
    
    override func storedVisibilityPref() -> OACommonBoolean {
        visibilityPref
    }
}
