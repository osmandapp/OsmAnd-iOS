//
//  WidgetInfoCreator.swift
//  OsmAnd Maps
//
//  Created by Paul on 10.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetInfoCreator)
@objcMembers
class WidgetInfoCreator: NSObject {
    
    let appMode: OAApplicationMode
    
    init(appMode: OAApplicationMode) {
        self.appMode = appMode
    }
    
    func createWidgetInfo(factory: MapWidgetsFactory, widgetType: WidgetType, widgetParams: [String: Any]? = nil) -> MapWidgetInfo? {
        let mapWidget = factory.createMapWidget(widgetType: widgetType, widgetParams: widgetParams)
        if let mapWidget {
            return createWidgetInfo(widget: mapWidget)
        }
        return nil
    }
    
    func createCustomWidgetInfo(factory: MapWidgetsFactory, key: String, widgetType: WidgetType, widgetParams: [String: Any]? = nil) -> MapWidgetInfo? {
        let widget = factory.createMapWidget(customId: key, widgetType: widgetType, widgetParams: widgetParams)
        if let widget = widget {
            let panel = widgetType.getPanel(key, appMode: appMode)
            return createCustomWidgetInfo(widgetId: key, widget: widget, widgetType: widgetType, panel: panel)
        }
        return nil
    }
    
    func createWidgetInfo(widget: OABaseWidgetView) -> MapWidgetInfo? {
        guard let widgetType = widget.widgetType else {
            return nil
        }
        
        let widgetId = widgetType.id
        let panel = widgetType.getPanel(widgetId, appMode: appMode)
        let page = panel.getWidgetPage(widgetId, appMode: appMode)
        let order = panel.getWidgetOrder(widgetId, appMode: appMode)
        
        return createWidgetInfo(widgetId: widgetId, widget: widget, iconName: widgetType.iconName, message: widgetType.title, page: page, order: order, widgetPanel: panel)
    }
    
    func createExternalWidget(widgetId: String, widget: OABaseWidgetView, settingsIconName: String, message: String?, defaultPanel: WidgetsPanel, order: Int) -> MapWidgetInfo {
        let panel = getExternalWidgetPanel(widgetId: widgetId, defaultPanel: defaultPanel)
        let page = panel.getWidgetPage(widgetId, appMode: appMode)
        let savedOrder = panel.getWidgetOrder(widgetId, appMode: appMode)
        
        var updatedOrder = order
        if savedOrder != WidgetsPanel.DEFAULT_ORDER {
            updatedOrder = savedOrder
        }
        
        return createWidgetInfo(widgetId: widgetId, widget: widget, iconName: settingsIconName, message: message, page: page, order: updatedOrder, widgetPanel: panel)
    }
    
    private func getExternalWidgetPanel(widgetId: String, defaultPanel: WidgetsPanel) -> WidgetsPanel {
        let storedInLeftPanel = WidgetsPanel.leftPanel.getWidgetOrder(widgetId, appMode: appMode) != WidgetsPanel.DEFAULT_ORDER
        let storedInRightPanel = WidgetsPanel.rightPanel.getWidgetOrder(widgetId, appMode: appMode) != WidgetsPanel.DEFAULT_ORDER
        
        if storedInLeftPanel {
            return WidgetsPanel.leftPanel
        } else if storedInRightPanel {
            return WidgetsPanel.rightPanel
        }
        return defaultPanel
    }
    
    func createCustomWidgetInfo(widgetId: String, widget: OABaseWidgetView, widgetType: WidgetType, panel: WidgetsPanel) -> MapWidgetInfo {
        let page = panel.getWidgetPage(widgetId, appMode: appMode)
        let order = panel.getWidgetOrder(widgetId, appMode: appMode)
        return createWidgetInfo(widgetId: widgetId, widget: widget, iconName: widgetType.iconName, message: widgetType.title, page: page, order: order, widgetPanel: panel)
    }
    
    func createWidgetInfo(widgetId: String, widget: OABaseWidgetView, iconName: String, message: String?, page: Int, order: Int, widgetPanel: WidgetsPanel) -> MapWidgetInfo {
        if let simpleWidget = widget as? OASimpleWidget {
            return SimpleWidgetInfo(key: widgetId, simpleWidget: simpleWidget, settingsIconId: iconName, message: message ?? "", page: page, order: order, widgetPanel: widgetPanel)
        }
        if let textInfoWidget = widget as? OATextInfoWidget {
            return SideWidgetInfo(key: widgetId, textWidget: textInfoWidget, settingsIconId: iconName, message: message ?? "", page: page, order: order, widgetPanel: widgetPanel)
        } else {
            return CenterWidgetInfo(key: widgetId, widget: widget, settingsIconId: iconName, message: message ?? "", page: page, order: order, widgetPanel: widgetPanel)
        }
    }
}
