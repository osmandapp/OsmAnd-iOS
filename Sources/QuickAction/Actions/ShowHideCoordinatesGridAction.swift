//
//  ShowHideCoordinatesGridAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 02.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ShowHideCoordinatesGridAction: OAQuickAction {
    private static let type = QuickActionType(id: QuickActionIds.showHideCoordinatesGridAction.rawValue, stringId: "coordinates_grid.showhide", cl: ShowHideCoordinatesGridAction.self)
        .name(localizedString("layer_coordinates_grid"))
        .nameAction(localizedString("quick_action_verb_show_hide"))
        .iconName("ic_action_world_globe")
        .nonEditable()
        .category(QuickActionTypeCategory.configureMap.rawValue)
    
    private lazy var gridSettings = OACoordinatesGridSettings()
    
    override class func getType() -> QuickActionType {
        type
    }

    override init() {
        super.init(actionType: Self.getType())
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    override func getText() -> String? {
        localizedString("quick_action_showhide_coordinates_grid_descr")
    }
    
    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_action_world_globe")
    }
    
    override func getStateName() -> String? {
        let nameRes = localizedString(getName())
        let actionName = localizedString(isActionWithSlash() ? "shared_string_hide" : "shared_string_show")
        return String(format: localizedString("ltr_or_rtl_combine_via_dash"), actionName, nameRes)
    }
    
    override func getIconResName() -> String {
        isActionWithSlash() ? "ic_action_world_globe" : "ic_action_coordinates_grid_disabled"
    }
    
    override func isActionWithSlash() -> Bool {
        gridSettings.isEnabled()
    }
    
    override func execute() {
        gridSettings.toggleEnable()
    }
}
