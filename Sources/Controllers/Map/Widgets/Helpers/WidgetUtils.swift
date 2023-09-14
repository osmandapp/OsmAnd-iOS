//
//  WidgetUtils.swift
//  OsmAnd Maps
//
//  Created by Skalii on 27.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

final class WidgetUtils {
    static func reorderWidgets(orderedWidgets: [[String]],
                               panel: WidgetsPanel,
                               selectedAppMode: OAApplicationMode) {
        guard let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry else {
            return
        }
        let filter = KWidgetModeAvailable | kWidgetModeEnabled
        let mergedPanels = panel.getMergedPanels().filter { $0 != panel }
        let enabledWidgets: [String] = orderedWidgets.flatMap { $0 }
        var mergedWidgetInfos: NSMutableOrderedSet = widgetRegistry.getWidgetsForPanel(selectedAppMode,
                                                                                       filterModes: Int(filter),
                                                                                       panels: mergedPanels)
        var currentWidgetInfos: NSMutableOrderedSet = widgetRegistry.getWidgetsForPanel(selectedAppMode,
                                                                                        filterModes: Int(filter),
                                                                                        panels: [panel])
        var alreadyExist: [String] = []
        removeExistingAndDisableWidgets(currentWidgetInfos: currentWidgetInfos,
                                        mergedWidgetInfos: mergedWidgetInfos,
                                        enabledWidgets: enabledWidgets,
                                        alreadyExist: &alreadyExist,
                                        widgetRegistry: widgetRegistry,
                                        selectedAppMode: selectedAppMode,
                                        panel: panel)
        mergedWidgetInfos = widgetRegistry.getWidgetsForPanel(selectedAppMode,
                                                              filterModes: Int(filter),
                                                              panels: mergedPanels)
        currentWidgetInfos = widgetRegistry.getWidgetsForPanel(selectedAppMode,
                                                               filterModes: Int(filter),
                                                               panels: [panel])
        let newOrders = getNewWidgetOrders(orderedWidgets: orderedWidgets,
                                           enabledWidgets: enabledWidgets,
                                           mergedWidgetInfos: mergedWidgetInfos,
                                           alreadyExist: &alreadyExist,
                                           panel: panel,
                                           selectedAppMode: selectedAppMode,
                                           widgetRegistry: widgetRegistry)
        panel.setWidgetsOrder(pagedOrder: newOrders, appMode: selectedAppMode)
        widgetRegistry.reorderWidgets()
        OARootViewController.instance().mapPanel.recreateControls()
    }
    
    private static func createWidget(widgetId: String,
                                     panel: WidgetsPanel,
                                     widgetsFactory: MapWidgetsFactory,
                                     selectedAppMode: OAApplicationMode) -> MapWidgetInfo? {
        guard let widgetType = WidgetType.getById(widgetId) else {
            return nil
        }
        let id = widgetId.contains(MapWidgetInfo.DELIMITER) ? widgetId : WidgetType.getDuplicateWidgetId(widgetId)
        guard let widget = widgetsFactory.createMapWidget(customId: id, widgetType: widgetType) else {
            return nil
        }
        OAAppSettings.sharedManager().customWidgetKeys.add(id)
        let creator = WidgetInfoCreator(appMode: selectedAppMode)
        return creator.createCustomWidgetInfo(widgetId: id,
                                              widget: widget,
                                              widgetType: widgetType,
                                              panel: panel)
    }
    
    private static func removeExistingAndDisableWidgets(currentWidgetInfos: NSMutableOrderedSet,
                                                        mergedWidgetInfos: NSMutableOrderedSet,
                                                        enabledWidgets: [String],
                                                        alreadyExist: inout [String],
                                                        widgetRegistry: OAMapWidgetRegistry,
                                                        selectedAppMode: OAApplicationMode,
                                                        panel: WidgetsPanel) {
        for mapWidgetInfo in currentWidgetInfos {
            guard let widgetInfo = mapWidgetInfo as? MapWidgetInfo else {
                continue
            }
            if enabledWidgets.contains(widgetInfo.key), !alreadyExist.contains(widgetInfo.key) {
                alreadyExist.append(widgetInfo.key)
            } else {
                widgetRegistry.getWidgetsFor(panel)?.remove(widgetInfo)
                if !mergedWidgetInfos.contains(widgetInfo), widgetInfo.isEnabledForAppMode(selectedAppMode) {
                    widgetRegistry.enableDisableWidget(for: selectedAppMode,
                                                       widgetInfo: widgetInfo,
                                                       enabled: NSNumber(value: false),
                                                       recreateControls: false)
                }
            }
        }
    }
    
    private static func getDefaultWidgetInfos(widgetRegistry: OAMapWidgetRegistry,
                                              selectedAppMode: OAApplicationMode,
                                              panel: WidgetsPanel) -> [MapWidgetInfo] {
        widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: 0, panels: panel.getMergedPanels()).array as? [MapWidgetInfo] ?? []
            .filter { !$0.key.contains(MapWidgetInfo.DELIMITER) }
    }
    
    private static func getNewWidgetOrders(orderedWidgets: [[String]],
                                           enabledWidgets: [String],
                                           mergedWidgetInfos: NSMutableOrderedSet,
                                           alreadyExist: inout [String],
                                           panel: WidgetsPanel,
                                           selectedAppMode: OAApplicationMode,
                                           widgetRegistry: OAMapWidgetRegistry) -> [[String]] {
        let widgetsFactory = MapWidgetsFactory()
        let defaultWidgetInfos = getDefaultWidgetInfos(widgetRegistry: widgetRegistry,
                                                       selectedAppMode: selectedAppMode,
                                                       panel: panel)
        var newOrders: [[String]] = []
        alreadyExist.removeAll()
        for page in orderedWidgets {
            var newOrder: [String] = []
            for enabledWidget in page {
                var needToAdd = false
                var mapWidgetInfo: MapWidgetInfo? = widgetRegistry.getWidgetInfo(byId: enabledWidget)
                if mapWidgetInfo == nil {
                    let isCustom = enabledWidget.contains(MapWidgetInfo.DELIMITER)
                    if isCustom {
                        mapWidgetInfo = createWidget(widgetId: enabledWidget,
                                                     panel: panel,
                                                     widgetsFactory: widgetsFactory,
                                                     selectedAppMode: selectedAppMode)
                        if let mapWidgetInfo {
                            alreadyExist.append(mapWidgetInfo.key)
                            needToAdd = true
                        }
                    } else if WidgetType.getById(enabledWidget) != nil {
                        for defaultWidgetInfo in defaultWidgetInfos where defaultWidgetInfo.key == enabledWidget {
                            mapWidgetInfo = defaultWidgetInfo
                            if let mapWidgetInfo {
                                alreadyExist.append(mapWidgetInfo.key)
                                needToAdd = true
                            }
                            break
                        }
                    }
                } else if let widgetInfo = mapWidgetInfo {
                    if !mergedWidgetInfos.contains(widgetInfo), !alreadyExist.contains(widgetInfo.key) {
                        alreadyExist.append(widgetInfo.key)
                        needToAdd = true
                    } else if alreadyExist.contains(widgetInfo.key) || mergedWidgetInfos.contains(widgetInfo) {
                        mapWidgetInfo = createWidget(widgetId: WidgetType.getDefaultWidgetId(enabledWidget),
                                                     panel: panel,
                                                     widgetsFactory: widgetsFactory,
                                                     selectedAppMode: selectedAppMode)
                        if let mapWidgetInfo {
                            alreadyExist.append(mapWidgetInfo.key)
                            needToAdd = true
                        }
                    }
                }
                if let mapWidgetInfo, needToAdd {
                    newOrder.append(mapWidgetInfo.key)
                    if !widgetRegistry.isWidgetVisible(mapWidgetInfo.key) {
                        mapWidgetInfo.priority = newOrder.firstIndex(of: mapWidgetInfo.key) ?? newOrder.count - 1
                        mapWidgetInfo.pageIndex = newOrders.firstIndex(of: newOrder) ?? newOrders.count
                        widgetRegistry.getWidgetsFor(panel)?.add(mapWidgetInfo)
                        widgetRegistry.enableDisableWidget(for: selectedAppMode,
                                                           widgetInfo: mapWidgetInfo,
                                                           enabled: NSNumber(value: true),
                                                           recreateControls: false)
                    }
                }
            }
            if !newOrder.isEmpty {
                newOrders.append(newOrder)
            }
        }
        return newOrders
    }
}
