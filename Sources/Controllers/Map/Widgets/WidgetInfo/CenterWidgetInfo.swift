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
        let settings = OAAppSettings.sharedManager()!
        let widgetType = getWidgetType()
        
        if (widgetType.defaultPanel == .bottomPanel && WidgetsPanel.topPanel.contains(widgetId: key)) {
            widgetPanel = .topPanel;
        } else if (widgetType.defaultPanel == .topPanel && WidgetsPanel.bottomPanel.contains(widgetId: key)) {
            widgetPanel = .bottomPanel
        } else {
            widgetPanel = widgetType.defaultPanel
        }
        return widgetPanel
    }
}
