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
    
    private let settingsIconId: String
    private let message: String
    private let widgetState: OAWidgetState?
    
    init(key: String,
         widget: OABaseWidgetView,
         settingsIconId: String,
         message: String,
         page: Int,
         order: Int,
         widgetPanel: WidgetsPanel) {
        self.key = key
        self.widget = widget
        self.widgetState = widget.getWidgetState()
        self.settingsIconId = settingsIconId
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
            return settingsIconId
        }
    }
    
    func getMapIconId(nightMode: Bool) -> String? {
        if let textInfoWidget = widget as? OATextInfoWidget {
            return textInfoWidget.getIconName()
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
    
    func getWidgetType() -> WidgetType? {
        return widget.widgetType
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
    
    func getWidgetTitle() -> String {
        widgetState?.getWidgetTitle() ?? getMessage()
    }
    
    func getExternalProviderPackage() -> String? {
        return nil
    }
    
    func getUpdatedPanel() -> WidgetsPanel {
        fatalError("Subclass must override")
    }
    
    func isEnabledForAppMode(_ appMode: OAApplicationMode) -> Bool {
        let widgetsVisibility = getWidgetsVisibility(appMode)
        if widgetsVisibility.contains(key) || widgetsVisibility.contains(COLLAPSED_PREFIX + key) {
            return true
        } else if widgetsVisibility.contains(HIDE_PREFIX + key) {
            return false
        }
        return WidgetsAvailabilityHelper.isWidgetVisibleByDefault(widgetId: key, appMode: appMode)
    }
    
    func getSettingsData(_ appMode: OAApplicationMode) -> OATableDataModel? {
        widget.getSettingsData(appMode)
    }
    
    func getSettingsDataForSimpleWidget(_ appMode: OAApplicationMode) -> OATableDataModel? {
        widget.getSettingsData(forSimpleWidget: appMode)
    }
    
    func enableDisable(appMode: OAApplicationMode, enabled: NSNumber?) {
        var widgetsVisibility: [String] = getWidgetsVisibility(appMode)
        widgetsVisibility.removeAll(where: { $0 == key })
        widgetsVisibility.removeAll(where: { $0 == COLLAPSED_PREFIX + key })
        widgetsVisibility.removeAll(where: { $0 == HIDE_PREFIX + key })
        widgetsVisibility.removeAll(where: { $0 == "" })

        if let enabled = enabled, (!isCustomWidget() || enabled.boolValue) {
            widgetsVisibility.append(enabled.boolValue ? key : HIDE_PREFIX + key)
        }

        var newVisibilityString = ""
        for visibility in widgetsVisibility {
            newVisibilityString.append(visibility + SETTINGS_SEPARATOR)
        }
        if !newVisibilityString.isEmpty {
            newVisibilityString.removeLast()
        }

        getVisibilityPreference().set(newVisibilityString, mode: appMode)

        if let settingsPref = widget.getWidgetSettingsPref(toReset: appMode), (enabled == nil || !enabled!.boolValue) {
            settingsPref.resetMode(toDefault: appMode)
        }
    }
    
    private func getWidgetsVisibility(_ appMode: OAApplicationMode) -> [String] {
        let widgetsVisibilityString = getVisibilityPreference().get(appMode)
        guard let widgetsVisibilityString else { return [] }
        return widgetsVisibilityString.components(separatedBy: SETTINGS_SEPARATOR)
    }
    
    private func getVisibilityPreference() -> OACommonString {
        OAAppSettings.sharedManager().mapInfoControls
    }

    override func isEqual(_ obj: Any?) -> Bool {
        guard let other = obj as? MapWidgetInfo else {
            return false
        }
        return key == other.key && getMessage() == other.getMessage()
    }
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(message)
        hasher.combine(key)
        hasher.combine(widget)
        hasher.combine(priority)
        hasher.combine(pageIndex)
        hasher.combine(widgetPanel)
        return hasher.finalize()
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

