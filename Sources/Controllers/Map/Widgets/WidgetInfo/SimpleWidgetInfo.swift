//
//  SimpleWidgetInfo.swift
//  OsmAnd Maps
//
//  Created by Skalii on 15.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OASimpleWidgetInfo)
class SimpleWidgetInfo: MapWidgetInfo {

    init(key: String,
         simpleWidget: OABaseWidgetView,
         settingsIconId: String,
         message: String,
         page: Int,
         order: Int,
         widgetPanel: WidgetsPanel) {
        super.init(key: key, widget: simpleWidget, settingsIconId: settingsIconId, message: message, page: page, order: order, widgetPanel: widgetPanel)
//        if let message = message {
//            widget.setContentTitle(message)
//        } else if messageId != MapWidgetInfo.INVALID_ID {
//            widget.setContentTitle(messageId)
//        }
    }
        
//        override func setWidgetPanel(_ widgetPanel: WidgetsPanel) {
//            self.widgetPanel = widgetPanel
//            (widget as! SimpleWidget).recreateViewIfNeeded(widgetPanel)
//        }
        
        override func getUpdatedPanel() -> WidgetsPanel {
            let widgetType = getWidgetType()
            if let widgetType = widgetType {
                return widgetType.getPanel(key, appMode: OAAppSettings.sharedManager().applicationMode.get())
            } else {
                WidgetType.findWidgetPanel(widgetId: key, mode: nil)
            }
            return widgetPanel
        }
}
