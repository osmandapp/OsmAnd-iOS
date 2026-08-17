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
         settingsIconId: String,
         message: String,
         page: Int,
         order: Int,
         widgetPanel: WidgetsPanel,
         appMode: OAApplicationMode,
         screenLayoutMode: ScreenLayoutMode) {
        super.init(key: key, widget: textWidget, settingsIconId: settingsIconId, message: message, page: page, order: order, widgetPanel: widgetPanel, appMode: appMode, screenLayoutMode: screenLayoutMode)
        
        textWidget.setContentTitle(getWidgetTitle())
    }
    
    func setExternalProviderPackage(_ externalProviderPackage: String) {
        self.externalProviderPackage = externalProviderPackage
    }
    
    override func getExternalProviderPackage() -> String? {
        return externalProviderPackage
    }
    
    override func getUpdatedPanel() -> WidgetsPanel {
        let widgetType = getWidgetType()
        if let widgetType {
            if widgetType.defaultPanel == .leftPanel, WidgetsPanel.rightPanel.contains(widgetId: key, appMode: appMode, screenLayoutMode: screenLayoutMode) {
                widgetPanel = .rightPanel
            } else if widgetType.defaultPanel == .rightPanel, WidgetsPanel.leftPanel.contains(widgetId: key, appMode: appMode, screenLayoutMode: screenLayoutMode) {
                widgetPanel = .leftPanel
            } else {
                widgetPanel = widgetType.defaultPanel
            }
        } else {
            widgetPanel = WidgetsPanel.leftPanel.contains(widgetId: key, appMode: appMode, screenLayoutMode: screenLayoutMode) ? .leftPanel : .rightPanel
        }
        
        return widgetPanel
    }
}
