//
//  SideWidgetInfo.swift
//  OsmAnd Maps
//
//  Created by Paul on 04.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OASideWidgetInfo)
@objcMembers
class SideWidgetInfo: MapWidgetInfo {
    private var externalProviderPackage: String?
    
    init(key: String,
         textWidget: OATextInfoWidget,
         daySettingsIconId: String,
         nightSettingsIconId: String,
         message: String,
         page: Int,
         order: Int,
         widgetPanel: WidgetsPanel) {
        super.init(key: key, widget: textWidget, daySettingsIconId: daySettingsIconId, nightSettingsIconId: nightSettingsIconId, message: message, page: page, order: order, widgetPanel: widgetPanel)
        
        textWidget.setContentTitle(getMessage())
    }
    
    func setExternalProviderPackage(_ externalProviderPackage: String) {
        self.externalProviderPackage = externalProviderPackage
    }
    
    override func getExternalProviderPackage() -> String? {
        return externalProviderPackage
    }
    
    override func getUpdatedPanel() -> WidgetsPanel {
        let settings = OAAppSettings.sharedManager()
        let widgetType = getWidgetType()
        if widgetType.defaultPanel == .leftPanel, WidgetsPanel.rightPanel.contains(widgetId: key) {
            widgetPanel = .rightPanel
        } else if widgetType.defaultPanel == .rightPanel, WidgetsPanel.leftPanel.contains(widgetId: key) {
            widgetPanel = .leftPanel
        } else {
            widgetPanel = widgetType.defaultPanel
        }
        return widgetPanel
    }
    
    override func isEnabledForAppMode(_ appMode: OAApplicationMode) -> Bool {
        let widgetsVisibility = getWidgetsVisibility(appMode: appMode)
        if widgetsVisibility.contains(key) || widgetsVisibility.contains(COLLAPSED_PREFIX + key) {
            return true
        } else if widgetsVisibility.contains(HIDE_PREFIX + key) {
            return false
        }
        return WidgetsAvailabilityHelper.isWidgetVisibleByDefault(widgetId: key, appMode: appMode)
    }
    
    override func enableDisable(appMode: OAApplicationMode, enabled: NSNumber?) {
        var widgetsVisibility = getWidgetsVisibility(appMode: appMode)
        widgetsVisibility.removeAll { $0 == key || $0 == COLLAPSED_PREFIX + key || $0 == HIDE_PREFIX + key }
        
        if let enabled, (!isCustomWidget() || enabled.boolValue) {
            widgetsVisibility.append(enabled.boolValue ? key : HIDE_PREFIX + key)
        }
        
        let newVisibilityString = widgetsVisibility.joined(separator: SETTINGS_SEPARATOR)
        getVisibilityPreference().set(newVisibilityString, mode: appMode)
        
        if let settingsPref = widget.getWidgetSettingsPref(toReset: appMode), (enabled == nil || !enabled!.boolValue) {
            settingsPref.resetMode(toDefault: appMode)
        }
    }
    
    private func getWidgetsVisibility(appMode: OAApplicationMode) -> [String] {
        if let widgetsVisibilityString = getVisibilityPreference().get(appMode) {
            return widgetsVisibilityString.components(separatedBy: SETTINGS_SEPARATOR)
        }
        return [String]()
    }
    
    private func getVisibilityPreference() -> OACommonString {
        return OAAppSettings.sharedManager().mapInfoControls
    }
}

