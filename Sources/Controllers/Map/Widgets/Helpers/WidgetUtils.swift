//
//  WidgetUtils.swift
//  OsmAnd Maps
//
//  Created by Skalii on 27.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

extension WidgetUtils {
    
    static func createNewWidgets(widgetsIds: [String],
                                 panel: WidgetsPanel,
                                 appMode: OAApplicationMode,
                                 recreateControls: Bool = true,
                                 selectedWidget: String?,
                                 widgetParams: [String: Any]?,
                                 addToNext: Bool?) -> [MapWidgetInfo] {
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
        let widgetsFactory = MapWidgetsFactory()
        
        var resultWidgetsInfos = [MapWidgetInfo]()
        for widgetId in widgetsIds {
            if let widgetInfo = createWidget(widgetId: widgetId,
                                             panel: panel,
                                             widgetsFactory: widgetsFactory,
                                             selectedAppMode: appMode,
                                             widgetParams: widgetParams) {
                if let addToNext, let selectedWidget {
                    addWidgetToSpecificPlace(with: widgetInfo,
                                             widgetsPanel: panel,
                                             selectedAppMode: appMode,
                                             selectedWidget: selectedWidget,
                                             addToNext: addToNext)
                } else {
                    addWidgetToEnd(with: widgetInfo, widgetsPanel: panel, selectedAppMode: appMode)
                }
                resultWidgetsInfos.append(widgetInfo)
                widgetRegistry.enableDisableWidget(for: appMode, widgetInfo: widgetInfo, enabled: true, recreateControls: false)
            }
        }
        widgetRegistry.reorderWidgets()
        OARootViewController.instance().mapPanel.recreateControls()
        return resultWidgetsInfos
    }
    
    private static func addWidgetToEnd(with targetWidget: MapWidgetInfo,
                                       widgetsPanel: WidgetsPanel,
                                       selectedAppMode: OAApplicationMode) {
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
        var pagedOrder: [Int: [String]] = [:]
        let enabledWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Int(kWidgetModeEnabled | kWidgetModeMatchingPanels), panels: [widgetsPanel])
        
        widgetRegistry.getWidgetsFor(targetWidget.widgetPanel).remove(targetWidget)
        
        targetWidget.widgetPanel = widgetsPanel
        
        let sortedWidgets = (enabledWidgets!.array as! [MapWidgetInfo]).sorted { $0.priority < $1.priority }
        
        for widget in sortedWidgets {
            guard let widgetItem = widget as? MapWidgetInfo else {
                continue
            }
            let page = widgetItem.pageIndex
            var orders = pagedOrder[page, default: []]
            orders.append(widgetItem.key)
            pagedOrder[page] = orders
        }
        
        if pagedOrder.isEmpty {
            targetWidget.pageIndex = 0
            targetWidget.priority = 0
            widgetRegistry.getWidgetsFor(targetWidget.widgetPanel).add(targetWidget)
            
            var flatOrder: [[String]] = []
            flatOrder.append([targetWidget.key])
            widgetsPanel.setWidgetsOrder(pagedOrder: flatOrder, appMode: selectedAppMode)
        } else {
            let sortedPagedOrder = pagedOrder.sorted { $0.key < $1.key }
            
            let pages = sortedPagedOrder.map { $0.key }
            var orders = sortedPagedOrder.map { $0.value }
            
            var lastPageOrder = orders.last ?? []
            
            if widgetsPanel.isPanelVertical, WidgetType.isComplexWidget(targetWidget.key) || (lastPageOrder.count == 1 && WidgetType.isComplexWidget(lastPageOrder.first ?? "")) {
                let newPage: [String] = [targetWidget.key]
                orders.append(newPage)
                targetWidget.pageIndex = getNewNextPageIndex(pages: pages) + 1
                targetWidget.priority = 0
            } else {
                lastPageOrder.append(targetWidget.key)
                
                if lastPageOrder.count > 1 {
                    let previousLastWidgetId = lastPageOrder[lastPageOrder.count - 2]
                    
                    if let previousLastVisibleWidgetInfo = widgetRegistry.getWidgetInfo(byId: previousLastWidgetId) {
                        targetWidget.pageIndex = previousLastVisibleWidgetInfo.pageIndex
                        targetWidget.priority = previousLastVisibleWidgetInfo.priority + 1
                    } else {
                        targetWidget.pageIndex = pages.last ?? 0
                        targetWidget.priority = lastPageOrder.count - 1
                    }
                } else {
                    targetWidget.pageIndex = pages.last ?? 0
                    targetWidget.priority = 0
                }
                orders[orders.count - 1] = lastPageOrder
            }
            widgetRegistry.getWidgetsFor(widgetsPanel).add(targetWidget)
            widgetsPanel.setWidgetsOrder(pagedOrder: orders, appMode: selectedAppMode)
        }
    }
    
    private static func addWidgetToSpecificPlace(with targetWidget: MapWidgetInfo,
                                                 widgetsPanel: WidgetsPanel,
                                                 selectedAppMode: OAApplicationMode,
                                                 selectedWidget: String,
                                                 addToNext: Bool) {
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
        var pagedOrder = [Int: [String]]()
        
        let enabledWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Int(kWidgetModeEnabled | kWidgetModeMatchingPanels), panels: [widgetsPanel])
        let sortedWidgets = (enabledWidgets!.array as! [MapWidgetInfo]).sorted { $0.priority < $1.priority }
        
        widgetRegistry.getWidgetsFor(targetWidget.widgetPanel).remove(targetWidget)
        targetWidget.widgetPanel = widgetsPanel
        
        for widget in sortedWidgets {
            guard let widgetItem = widget as? MapWidgetInfo else {
                continue
            }
            let page = widgetItem.pageIndex
            var orders = pagedOrder[page, default: []]
            orders.append(widgetItem.key)
            pagedOrder[page] = orders
        }
        
        if pagedOrder.isEmpty {
            targetWidget.pageIndex = 0
            targetWidget.priority = 0
            widgetRegistry.getWidgetsFor(widgetsPanel).add(targetWidget)
            
            var flatOrder = [[String]]()
            flatOrder.append([targetWidget.key])
            widgetsPanel.setWidgetsOrder(pagedOrder: flatOrder, appMode: selectedAppMode)
        } else {
            let sortedPagedOrder = pagedOrder.sorted { $0.key < $1.key }
            var orders = sortedPagedOrder.map { $0.value }
            var insertPage = 0
            var insertOrder = 0
            
            for (pageIndex, widgetPage) in orders.enumerated() {
                for (orderIndex, widgetId) in widgetPage.enumerated() where widgetId == selectedWidget {
                    insertPage = pageIndex
                    insertOrder = orderIndex
                }
            }
            
            var pageToAddWidget = orders[insertPage]
            if addToNext {
                insertOrder += 1
            }
            pageToAddWidget.insert(targetWidget.key, at: insertOrder)
            
            for (index, widgetId) in pageToAddWidget.enumerated() {
                if let widgetInfo = widgetRegistry.getWidgetInfo(byId: widgetId) {
                    widgetInfo.pageIndex = insertPage
                    widgetInfo.priority = index
                } else if widgetId == targetWidget.key {
                    targetWidget.pageIndex = insertPage
                    targetWidget.priority = index
                }
            }
            orders[insertPage] = pageToAddWidget
            
            widgetRegistry.getWidgetsFor(widgetsPanel).add(targetWidget)
            widgetsPanel.setWidgetsOrder(pagedOrder: orders, appMode: selectedAppMode)
        }
    }
    
    private static func getNewNextPageIndex(pages: [Int]) -> Int {
        pages.max() ?? 0
    }
}

final class WidgetUtils {
    
    static func reorderWidgets(orderedWidgetPages: [[String]],
                               panel: WidgetsPanel,
                               selectedAppMode: OAApplicationMode,
                               widgetParams: [String: Any]? = nil) {
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
        
        let enabledWidgets: [String] = orderedWidgetPages.flatMap { $0 }
        removeUnusedWidgets(enabledWidgets: enabledWidgets, panel: panel, appMode: selectedAppMode, widgetRegistry: widgetRegistry)
        
        let newOrders = createNewOrders(enabledWidgets: enabledWidgets,
                                        orderedWidgetPages: orderedWidgetPages,
                                        panel: panel,
                                        appMode: selectedAppMode,
                                        widgetRegistry: widgetRegistry,
                                        widgetParams: widgetParams)
        
        panel.setWidgetsOrder(pagedOrder: newOrders, appMode: selectedAppMode)
        widgetRegistry.reorderWidgets()
        OARootViewController.instance().mapPanel.recreateControls()
    }
    
    private static func removeUnusedWidgets(enabledWidgets: [String],
                                            panel: WidgetsPanel,
                                            appMode: OAApplicationMode,
                                            widgetRegistry: OAMapWidgetRegistry) {
        let filter = kWidgetModeEnabled | kWidgetModeMatchingPanels
        let currentWidgetInfos: NSMutableOrderedSet = widgetRegistry.getWidgetsForPanel(appMode,
                                                                                        filterModes: Int(filter),
                                                                                        panels: [panel])
        let widgetsToDelete: [MapWidgetInfo] = (currentWidgetInfos.array as! [MapWidgetInfo]).filter { !enabledWidgets.contains($0.key) }
        if !widgetsToDelete.isEmpty {
            let widgets: NSMutableOrderedSet = widgetRegistry.getWidgetsFor(panel)
            for widgetInfo in widgetsToDelete where widgets.contains(widgetInfo) {
                widgets.remove(widgetInfo)
                widgetRegistry.enableDisableWidget(for: appMode,
                                                   widgetInfo: widgetInfo,
                                                   enabled: NSNumber(value: false),
                                                   recreateControls: false)
            }
        }
    }
    
    private static func createNewOrders(enabledWidgets: [String],
                                        orderedWidgetPages: [[String]],
                                        panel: WidgetsPanel,
                                        appMode: OAApplicationMode,
                                        widgetRegistry: OAMapWidgetRegistry,
                                        widgetParams: [String: Any]? = nil) -> [[String]] {
        let newWidgetsList: NSMutableArray = buildNewWidgetsList(enabledWidgets: enabledWidgets, panel: panel, appMode: appMode, widgetRegistry: widgetRegistry, widgetParams: widgetParams)
        var newOrders = [[String]]()
        for page in orderedWidgetPages {
            var newOrder: [String] = []
            for enabledWidget in page {
                let mapWidgetInfo: MapWidgetInfo? = newWidgetsList.first(where: { ($0 as! MapWidgetInfo).key.hasPrefix(enabledWidget) }) as? MapWidgetInfo
                if let mapWidgetInfo {
                    newWidgetsList.remove(mapWidgetInfo)
                    newOrder.append(mapWidgetInfo.key)
                    updateWidgetParams(with: mapWidgetInfo, newOrder: newOrder, newOrders: newOrders, panel: panel, selectedAppMode: appMode, widgetRegistry: widgetRegistry)
                }
            }
            if !newOrder.isEmpty {
                newOrders.append(newOrder)
            }
        }
        return newOrders
    }
    
    private static func buildNewWidgetsList(enabledWidgets: [String],
                                            panel: WidgetsPanel,
                                            appMode: OAApplicationMode,
                                            widgetRegistry: OAMapWidgetRegistry,
                                            widgetParams: [String: Any]? = nil) -> NSMutableArray {
        let newWidgetsList = NSMutableArray()
        let widgetsFactory = MapWidgetsFactory()
        if !enabledWidgets.isEmpty {
            let currentWidgetIds = NSMutableArray(array: widgetRegistry.getWidgetsFor(panel).compactMap { ($0 as! MapWidgetInfo).key })
            for widgetInfoId in enabledWidgets {
                if !currentWidgetIds.contains(widgetInfoId) {
                    if let newMapWidgetInfo = createWidget(widgetId: widgetInfoId,
                                                           panel: panel,
                                                           widgetsFactory: widgetsFactory,
                                                           selectedAppMode: appMode,
                                                           widgetParams: widgetParams) {
                        newWidgetsList.add(newMapWidgetInfo)
                        currentWidgetIds.remove(widgetInfoId)
                    }
                } else {
                    if let mapWidgetInfo = widgetRegistry.getWidgetInfo(byId: widgetInfoId) {
                        newWidgetsList.add(mapWidgetInfo)
                        currentWidgetIds.remove(widgetInfoId)
                    }
                }
            }
        }
        return newWidgetsList
    }
    
    private static func createWidget(widgetId: String,
                                     panel: WidgetsPanel,
                                     widgetsFactory: MapWidgetsFactory,
                                     selectedAppMode: OAApplicationMode,
                                     widgetParams: [String: Any]? = nil) -> MapWidgetInfo? {
        guard let widgetType = WidgetType.getById(widgetId) else {
            return nil
        }
        let id = widgetId.contains(MapWidgetInfo.DELIMITER) ? widgetId : WidgetType.getDuplicateWidgetId(widgetId)
        guard let widget = widgetsFactory.createMapWidget(customId: id, widgetType: widgetType, widgetParams: widgetParams) else {
            return nil
        }
        OAAppSettings.sharedManager().customWidgetKeys.add(id)
        let creator = WidgetInfoCreator(appMode: selectedAppMode)
        return creator.createCustomWidgetInfo(widgetId: id,
                                              widget: widget,
                                              widgetType: widgetType,
                                              panel: panel)
    }
    
    static func updateWidgetParams(with mapWidgetInfo: MapWidgetInfo,
                                   newOrder: [String],
                                   newOrders: [[String]],
                                   panel: WidgetsPanel,
                                   selectedAppMode: OAApplicationMode,
                                   widgetRegistry: OAMapWidgetRegistry) {
        guard !widgetRegistry.isWidgetVisible(mapWidgetInfo.key) else {
            return
        }
        mapWidgetInfo.priority = newOrder.firstIndex(of: mapWidgetInfo.key) ?? newOrder.count - 1
        mapWidgetInfo.pageIndex = newOrders.firstIndex(of: newOrder) ?? newOrders.count
        widgetRegistry.getWidgetsFor(panel)?.add(mapWidgetInfo)
        widgetRegistry.enableDisableWidget(for: selectedAppMode,
                                           widgetInfo: mapWidgetInfo,
                                           enabled: NSNumber(value: true),
                                           recreateControls: false)
    }
}
