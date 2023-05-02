//
//  WidgetState.swift
//  OsmAnd Maps
//
//  Created by Paul on 02.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
@objc(OAWidgetState)
class WidgetState: NSObject {
    
    func getMenuTitle() -> String? {
        return nil
    }

    func getMenuDescription() -> String? {
        return nil
    }

    func getMenuIconId() -> String? {
        return nil
    }

    func getMenuItemId() -> String? {
        return nil
    }

    func getMenuTitles() -> ([NSString]?) {
        return nil
    }

    func getMenuDescriptions() -> ([String]?) {
        return nil
    }

    func getMenuIconIds() -> ([String]?) {
        return nil
    }

    func getMenuItemIds() -> ([String]?) {
        return nil
    }

    func changeState(stateId: String) {
        
    }

    func getSettingsIconId(nightMode: Bool) -> String? {
        return nil
    }

    func changeToNextState() {
        
    }
        
    func copyPrefs(appMode: OAApplicationMode, customId: String) {
        
    }
    
}
