//
//  SimpleWidgetInfo.swift
//  OsmAnd Maps
//
//  Created by Skalii on 15.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OASimpleWidgetInfo)
@objcMembers
class SimpleWidgetInfo: MapWidgetInfo {

    init(key: String,
         simpleWidget: OASimpleWidget,
         settingsIconId: String,
         message: String,
         page: Int,
         order: Int,
         widgetPanel: WidgetsPanel,
         appMode: OAApplicationMode,
         screenLayoutMode: ScreenLayoutMode) {
        super.init(key: key, widget: simpleWidget, settingsIconId: settingsIconId, message: message, page: page, order: order, widgetPanel: widgetPanel, appMode: appMode, screenLayoutMode: screenLayoutMode)

        simpleWidget.setContentTitle(getWidgetTitle())
    }

    override func getUpdatedPanel() -> WidgetsPanel {
        if let widgetType = widgetType() {
            return widgetType.panel(key,
                                    appMode: appMode,
                                    screenLayoutMode: screenLayoutMode)
        }
        return widgetPanel
    }
}
