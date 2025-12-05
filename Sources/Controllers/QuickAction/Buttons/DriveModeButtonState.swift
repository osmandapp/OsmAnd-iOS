//
//  DriveModeButtonState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class DriveModeButtonState: MapButtonState {
    static let hudId = "map.view.route_planning"
    
    lazy var visibilityPref: OACommonBoolean = OAAppSettings.sharedManager().registerBooleanPreference("\(id)_state", defValue: true)
    
    init() {
        super.init(withId: Self.hudId)
    }
    
    override func getName() -> String {
        localizedString("shared_string_navigation")
    }
    
    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_custom_navigation")
    }
    
    override func isEnabled() -> Bool {
        visibilityPref.get()
    }
    
    @discardableResult override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.companion.POS_LEFT, posV: ButtonPositionSize.companion.POS_BOTTOM, xMove: true, yMove: false)
    }
}
