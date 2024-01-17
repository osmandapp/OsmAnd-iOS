//
//  WidgetUtils.swift
//  OsmAnd Maps
//
//  Created by Skalii on 27.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

final class WidgetUtils {
    static func reorderWidgets(orderedWidgetPages: [[String]],
                               panel: WidgetsPanel,
                               selectedAppMode: OAApplicationMode,
                               widgetParams: [String: Any]? = nil) {
        guard let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry else {
            return
        }
        let filter = kWidgetModeEnabled | kWidgetModeMatchingPanels
        let enabledWidgets: [String] = orderedWidgetPages.flatMap { $0 }
        var mergedWidgetInfos: NSMutableOrderedSet = widgetRegistry.getWidgetsForPanel(selectedAppMode,
                                                                                       filterModes: Int(filter),
                                                                                       panels: [panel])
        var currentWidgetInfos: NSMutableOrderedSet = widgetRegistry.getWidgetsForPanel(selectedAppMode,
                                                                                        filterModes: Int(filter),
                                                                                        panels: [panel])
        removeExistingAndDisableWidgets(currentWidgetInfos: currentWidgetInfos,
                                        mergedWidgetInfos: mergedWidgetInfos,
                                        enabledWidgets: enabledWidgets,
                                        widgetRegistry: widgetRegistry,
                                        selectedAppMode: selectedAppMode,
                                        panel: panel)
        mergedWidgetInfos = widgetRegistry.getWidgetsForPanel(selectedAppMode,
                                                              filterModes: Int(filter),
                                                              panels: [panel])
        currentWidgetInfos = widgetRegistry.getWidgetsForPanel(selectedAppMode,
                                                               filterModes: Int(filter),
                                                               panels: [panel])
        let reorderWidgets = getReorderWidgets(orderedWidgetPages: orderedWidgetPages,
                                               enabledWidgets: enabledWidgets,
                                               mergedWidgetInfos: mergedWidgetInfos,
                                               panel: panel,
                                               selectedAppMode: selectedAppMode,
                                               widgetRegistry: widgetRegistry,
                                               widgetParams: widgetParams)
        panel.setWidgetsOrder(pagedOrder: reorderWidgets, appMode: selectedAppMode)
        widgetRegistry.reorderWidgets()
        OARootViewController.instance().mapPanel.recreateControls()
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
    
    private static func removeExistingAndDisableWidgets(currentWidgetInfos: NSMutableOrderedSet,
                                                        mergedWidgetInfos: NSMutableOrderedSet,
                                                        enabledWidgets: [String],
                                                        widgetRegistry: OAMapWidgetRegistry,
                                                        selectedAppMode: OAApplicationMode,
                                                        panel: WidgetsPanel) {
        var alreadyExist = [String]()
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
        widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: 0, panels: [panel]).array as? [MapWidgetInfo] ?? []
            .filter { !$0.key.contains(MapWidgetInfo.DELIMITER) }
    }
    
    private static func addWidgetInfoKeyIfNeeded(info: MapWidgetInfo?,
                                                 alreadyExist: inout [String],
                                                 needToAdd: inout Bool) {
        guard let info else {
            return
        }
        alreadyExist.append(info.key)
        needToAdd = true
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
    
    private static func getReorderWidgets(orderedWidgetPages: [[String]],
                                          enabledWidgets: [String],
                                          mergedWidgetInfos: NSMutableOrderedSet,
                                          panel: WidgetsPanel,
                                          selectedAppMode: OAApplicationMode,
                                          widgetRegistry: OAMapWidgetRegistry,
                                          widgetParams: [String: Any]? = nil) -> [[String]] {
        let widgetsFactory = MapWidgetsFactory()
        let defaultWidgetInfos = getDefaultWidgetInfos(widgetRegistry: widgetRegistry,
                                                       selectedAppMode: selectedAppMode,
                                                       panel: panel)
        var newOrders = [[String]]()
        var alreadyExist = [String]()
        
        for page in orderedWidgetPages {
            var newOrder: [String] = []
            for enabledWidget in page {
                var needToAdd = false
                var mapWidgetInfo: MapWidgetInfo? = widgetRegistry.getWidgetInfo(byId: enabledWidget)
                if let widgetInfo = mapWidgetInfo {
                    if !mergedWidgetInfos.contains(widgetInfo), !alreadyExist.contains(widgetInfo.key) {
                        addWidgetInfoKeyIfNeeded(info: widgetInfo, alreadyExist: &alreadyExist, needToAdd: &needToAdd)
                    } else if alreadyExist.contains(widgetInfo.key) || mergedWidgetInfos.contains(widgetInfo) {
                        mapWidgetInfo = createWidget(widgetId: WidgetType.getDefaultWidgetId(enabledWidget),
                                                     panel: panel,
                                                     widgetsFactory: widgetsFactory,
                                                     selectedAppMode: selectedAppMode, widgetParams: widgetParams)
                        addWidgetInfoKeyIfNeeded(info: mapWidgetInfo, alreadyExist: &alreadyExist, needToAdd: &needToAdd)
                    }
                } else {
                    if enabledWidget.contains(MapWidgetInfo.DELIMITER) {
                        mapWidgetInfo = createWidget(widgetId: enabledWidget,
                                                     panel: panel,
                                                     widgetsFactory: widgetsFactory,
                                                     selectedAppMode: selectedAppMode, widgetParams: widgetParams)
                        addWidgetInfoKeyIfNeeded(info: mapWidgetInfo, alreadyExist: &alreadyExist, needToAdd: &needToAdd)
                    } else if WidgetType.getById(enabledWidget) != nil {
                        for defaultWidgetInfo in defaultWidgetInfos where defaultWidgetInfo.key == enabledWidget {
                            mapWidgetInfo = defaultWidgetInfo
                            addWidgetInfoKeyIfNeeded(info: mapWidgetInfo, alreadyExist: &alreadyExist, needToAdd: &needToAdd)
                            break
                        }
                    }
                }
                if let mapWidgetInfo, needToAdd {
                    newOrder.append(mapWidgetInfo.key)
                    updateWidgetParams(with: mapWidgetInfo, newOrder: newOrder, newOrders: newOrders, panel: panel, selectedAppMode: selectedAppMode, widgetRegistry: widgetRegistry)
                }
            }
            if !newOrder.isEmpty {
                newOrders.append(newOrder)
            }
        }
        return newOrders
    }
}
