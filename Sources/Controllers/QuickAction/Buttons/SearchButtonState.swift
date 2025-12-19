//
//  SearchButtonState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class SearchButtonState: SwitchVisibilityMapButtonState {
    static let hudId = "map.view.quick_search"
    
    lazy var visibilityPref: OACommonBoolean = OAAppSettings.sharedManager().registerBooleanPreference("\(id)_state", defValue: true)
    
    init() {
        super.init(withId: Self.hudId)
    }
    
    override func getName() -> String {
        localizedString("shared_string_search")
    }
    
    override func defaultIconName() -> String {
        "ic_custom_search"
    }
    
    override func buttonDescription() -> String {
        localizedString("search_action_descr")
    }
    
    override func isEnabled() -> Bool {
        visibilityPref.get()
    }
    
    @discardableResult override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.companion.POS_LEFT, posV: ButtonPositionSize.companion.POS_TOP, xMove: true, yMove: false)
    }
    
    override func storedVisibilityPref() -> OACommonBoolean {
        visibilityPref
    }
}
