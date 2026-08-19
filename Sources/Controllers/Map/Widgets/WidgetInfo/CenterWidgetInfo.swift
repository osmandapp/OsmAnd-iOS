//
//  CenterWidgetInfo.swift
//  OsmAnd Maps
//
//  Created by Paul on 04.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OACenterWidgetInfo)
class CenterWidgetInfo: MapWidgetInfo {
    
    override func getUpdatedPanel() -> WidgetsPanel {
        let widgetType = widgetType()
        
        if let widgetType {
            if (widgetType.defaultPanel == .bottomPanel && WidgetsPanel.topPanel.contains(widgetId: key, appMode: appMode, screenLayoutMode: screenLayoutMode)) {
                widgetPanel = .topPanel;
            } else if (widgetType.defaultPanel == .topPanel && WidgetsPanel.bottomPanel.contains(widgetId: key, appMode: appMode, screenLayoutMode: screenLayoutMode)) {
                widgetPanel = .bottomPanel
            } else {
                widgetPanel = widgetType.defaultPanel
            }
        } else {
            widgetPanel = WidgetsPanel.topPanel.contains(widgetId: key, appMode: appMode, screenLayoutMode: screenLayoutMode) ? .topPanel : .bottomPanel
        }
        return widgetPanel
    }
}
