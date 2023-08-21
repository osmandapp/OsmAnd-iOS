//
//  WidgetUtils.swift
//  OsmAnd Maps
//
//  Created by Skalii on 27.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetUtils)
@objcMembers
class WidgetUtils: NSObject {

    static func addSelectedWidgets(widgetsIds: [String], panel: WidgetsPanel, selectedAppMode: OAApplicationMode) {
        let widgetsFactory = MapWidgetsFactory()
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry!
        let filter = KWidgetModeAvailable | kWidgetModeEnabled
        
        for widgetId in widgetsIds {
            var widgetInfo: MapWidgetInfo? = widgetRegistry.getWidgetInfo(byId: widgetId)
            let widgetInfos: NSMutableOrderedSet = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Int(filter), panels: WidgetsPanel.values)
            
            if widgetInfo == nil || widgetInfos.contains(widgetInfo!) {
                widgetInfo = createDuplicateWidget(widgetId: widgetId, panel: panel, widgetsFactory: widgetsFactory, selectedAppMode: selectedAppMode)
            }
            if let newWidgetInfo = widgetInfo {
                addWidgetToEnd(targetWidget: newWidgetInfo, widgetsPanel: panel, selectedAppMode: selectedAppMode)
                widgetRegistry.enableDisableWidget(for: selectedAppMode, widgetInfo: newWidgetInfo, enabled: NSNumber(value: true), recreateControls: false)
            }
        }
    
        OARootViewController.instance().mapPanel.recreateControls()
    }

    static func createDuplicateWidget(widgetId: String, panel: WidgetsPanel, widgetsFactory: MapWidgetsFactory, selectedAppMode: OAApplicationMode) -> MapWidgetInfo? {
        if let widgetType = WidgetType.getById(widgetId) {
            let id = widgetId.contains(MapWidgetInfo.DELIMITER) ? widgetId : WidgetType.getDuplicateWidgetId(widgetId)
            if let widget = widgetsFactory.createMapWidget(customId: id, widgetType: widgetType) {
                OAAppSettings.sharedManager().customWidgetKeys.add(id)
                let creator = WidgetInfoCreator(appMode: selectedAppMode)
                return creator.createCustomWidgetInfo(widgetId: id, widget: widget, widgetType: widgetType, panel: panel)
            }
        }
        return nil
    }

    static func addWidgetToEnd(targetWidget: MapWidgetInfo, widgetsPanel: WidgetsPanel, selectedAppMode: OAApplicationMode) {
        let widgetRegistry: OAMapWidgetRegistry = OAMapWidgetRegistry.sharedInstance()
        var pagedOrder: [Int: [String]] = [:]

        let enabledWidgets: NSMutableOrderedSet = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Int(kWidgetModeEnabled), panels: [widgetsPanel])

        widgetRegistry.getWidgetsFor(targetWidget.widgetPanel)?.remove(targetWidget)
        targetWidget.widgetPanel = widgetsPanel

        for enabledWidget in enabledWidgets {
            guard let widget = enabledWidget as? MapWidgetInfo else { continue }
            let page = widget.pageIndex
            if var orders = pagedOrder[page] {
                orders.append(widget.key)
                pagedOrder[page] = orders
            } else {
                pagedOrder[page] = [widget.key]
            }
        }

        if pagedOrder.isEmpty {
            targetWidget.pageIndex = 0
            targetWidget.priority = 0
            widgetRegistry.getWidgetsFor(widgetsPanel)?.add(targetWidget)

            let flatOrder: [[String]] = [ [targetWidget.key] ]
            widgetsPanel.setWidgetsOrder(pagedOrder: flatOrder, appMode: selectedAppMode)
        } else {
            let pages = Array(pagedOrder.keys)
            var orders = Array(pagedOrder.values)
            var lastPageOrder = orders.last ?? []

            lastPageOrder.append(targetWidget.key)

            if let previousLastWidgetId = lastPageOrder.dropLast().last,
               let previousLastVisibleWidgetInfo = widgetRegistry.getWidgetInfo(byId:previousLastWidgetId) {
                let lastPage = previousLastVisibleWidgetInfo.pageIndex
                let lastOrder = previousLastVisibleWidgetInfo.priority + 1
                targetWidget.pageIndex = lastPage
                targetWidget.priority = lastOrder
            } else {
                let lastPage = pages.last ?? 0
                let lastOrder = lastPageOrder.count - 1
                targetWidget.pageIndex = lastPage
                targetWidget.priority = lastOrder
            }

            widgetRegistry.getWidgetsFor(widgetsPanel)?.add(targetWidget)

            widgetsPanel.setWidgetsOrder(pagedOrder: orders, appMode: selectedAppMode)
        }
    }

}
