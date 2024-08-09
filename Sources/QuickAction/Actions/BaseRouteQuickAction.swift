//
//  BaseRouteQuickAction.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 08/08/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class BaseRouteQuickAction: OAQuickAction {

    class func getName() -> String {
        ""
    }
    
    class func getQuickActionType() -> QuickActionType {
        fatalError()
    }
    
    override init() {
        super.init(actionType: Self.getQuickActionType())
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    func isEnabled() -> Bool {
        false
    }
    
    override func isActionWithSlash() -> Bool {
        isEnabled()
    }
    
    override func getStateName() -> String? {
        let actionName = localizedString(isEnabled() ? "shared_string_hide" : "shared_string_show")
        return String(format: localizedString("ltr_or_rtl_combine_via_dash"), actionName, Self.getName())
    }
}
