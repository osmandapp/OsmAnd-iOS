//
//  MapWidgetInfo.swift
//  OsmAnd Maps
//
//  Created by Paul on 03.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAMapWidgetInfo)
@objcMembers
class MapWidgetInfo: NSObject, Comparable {
    
    static let DELIMITER = "__"
    static let INVALID_ID = 0
    
    let key: String
    let widget: OABaseWidgetView
    
    var widgetPanel: WidgetsPanel
    var priority: Int
    var pageIndex: Int
    
    private let daySettingsIconId: String
    private let nightSettingsIconId: String
    private let message: String
    private let widgetState: OAWidgetState?
    
    init(key: String,
         widget: OABaseWidgetView,
         daySettingsIconId: String,
         nightSettingsIconId: String,
         message: String,
         page: Int,
         order: Int,
         widgetPanel: WidgetsPanel) {
        self.key = key
        self.widget = widget
        self.widgetState = widget.getWidgetState()
        self.daySettingsIconId = daySettingsIconId
        self.nightSettingsIconId = nightSettingsIconId
        self.message = message
        self.pageIndex = page
        self.priority = order
        self.widgetPanel = widgetPanel
    }
    
    func isCustomWidget() -> Bool {
        return key.contains(MapWidgetInfo.DELIMITER)
    }
    
    func getWidgetState() -> OAWidgetState? {
        return widgetState
    }
    
    func getSettingsIconId(nightMode: Bool) -> String {
        if let widgetState = widgetState {
            return widgetState.getSettingsIconId(nightMode)
        } else {
            return nightMode ? nightSettingsIconId : daySettingsIconId
        }
    }
    
    func getMapIconId(nightMode: Bool) -> String? {
        if let textInfoWidget = widget as? OATextInfoWidget {
            return textInfoWidget.getIconName(nightMode)
        }
        return nil
    }
    
    func isIconPainted() -> Bool {
        let dayMapIconId = getMapIconId(nightMode: false)
        let nightMapIconId = getMapIconId(nightMode: true)
        let daySettingsIconId = getSettingsIconId(nightMode: false)
        let nightSettingsIconId = getSettingsIconId(nightMode: true)
        if let dayMapIconId, let nightMapIconId {
            return dayMapIconId != nightMapIconId
        } else {
            return daySettingsIconId != nightSettingsIconId
        }
    }
    
    func getWidgetType() -> WidgetType {
        return widget.widgetType!
    }
    
    func isExternal() -> Bool {
        return widget.isExternal()
    }
    
    func getTitle() -> String {
        return getMessage()
    }
    
    func getStateIndependentTitle() -> String {
        return message
    }
    
    func getMessage() -> String {
        return widgetState?.getMenuTitle() ?? message
    }
    
    func getExternalProviderPackage() -> String? {
        return nil
    }
    
    func getUpdatedPanel() -> WidgetsPanel {
        fatalError("Subclass must override")
    }
    
    func isEnabledForAppMode(_ appMode: OAApplicationMode) -> Bool {
        fatalError("Subclass must override")
    }
    
    func enableDisable(appMode: OAApplicationMode, enabled: NSNumber?) {
        // implementation
    }
    
    override func isEqual(_ obj: Any?) -> Bool {
        guard let other = obj as? MapWidgetInfo else {
            return false
        }
        return key == other.key && getMessage() == other.getMessage()
    }
    
    override var hash: Int {
        return getMessage().hashValue
    }

    static func < (lhs: MapWidgetInfo, rhs: MapWidgetInfo) -> Bool {
        if lhs.isEqual(rhs) {
            return false
        }
        if lhs.pageIndex != rhs.pageIndex {
            return lhs.pageIndex < rhs.pageIndex
        }
        if lhs.priority != rhs.priority {
            return lhs.priority < rhs.priority
        }
        if lhs.key != rhs.key {
            return lhs.key < rhs.key
        }
        return lhs.message < rhs.message
    }

    override var description: String {
        return key
    }

}

