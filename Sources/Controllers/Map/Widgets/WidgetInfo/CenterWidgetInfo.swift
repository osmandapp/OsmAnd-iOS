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
    
    override func getUpdatedPanel(_ appMode: OAApplicationMode,
                                  screenLayoutMode: NSNumber?) -> WidgetsPanel {
        let widgetType = widgetType()
        let layoutMode = screenLayoutMode.flatMap { ScreenLayoutMode(rawValue: $0.int32Value) } ?? self.screenLayoutMode
        let screenElementsMode = ScreenElementsMode(usesSeparateLayouts: screenLayoutMode != nil) // todo
        
        if let widgetType {
            if widgetType.defaultPanel == .bottomPanel,
               WidgetsPanel.topPanel.contains(widgetId: key,
                                              appMode: appMode,
                                              screenLayoutMode: layoutMode,
                                              screenElementsMode: screenElementsMode) {
                widgetPanel = .topPanel;
            } else if widgetType.defaultPanel == .topPanel,
                      WidgetsPanel.bottomPanel.contains(widgetId: key,
                                                        appMode: appMode,
                                                        screenLayoutMode: layoutMode,
                                                        screenElementsMode: screenElementsMode) {
                widgetPanel = .bottomPanel
            } else {
                widgetPanel = widgetType.defaultPanel
            }
        } else {
            widgetPanel = WidgetsPanel.topPanel.contains(widgetId: key,
                                                         appMode: appMode,
                                                         screenLayoutMode: layoutMode,
                                                         screenElementsMode: screenElementsMode) ? .topPanel : .bottomPanel
        }
        return widgetPanel
    }
}
