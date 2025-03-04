//
//  BaseMonitoringAction.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 21.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class BaseMonitoringAction: OAQuickAction {
    
    override init() {
        super.init(actionType: Self.getQuickActionType())
    }
    
    override init(actionType type: QuickActionType) {
        super.init(actionType: type)
    }
    
    override init(action: OAQuickAction) {
        super.init(action: action)
    }
    
    class func getQuickActionType() -> QuickActionType {
        fatalError("Subclasses must override getQuickActionType() to provide a valid QuickActionType.")
    }
    
    func isRecordingTrack() -> Bool {
        guard let plugin = getPlugin() else { return false }
        return plugin.isRecordingTrack()
    }
    
    func hasDataToSave() -> Bool {
        guard let plugin = getPlugin() else { return false }
        return plugin.hasDataToSave()
    }
    
    func getPlugin() -> OAMonitoringPlugin? {
        OAPluginsHelper.getPlugin(OAMonitoringPlugin.self) as? OAMonitoringPlugin
    }
}
