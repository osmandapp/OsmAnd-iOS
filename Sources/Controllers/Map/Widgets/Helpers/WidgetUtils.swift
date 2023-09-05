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

    static func setEnabledWidgets(orderedWidgets: [[String]],
                                  panel: WidgetsPanel,
                                  selectedAppMode: OAApplicationMode) {
        let widgetsFactory = MapWidgetsFactory()
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry!
        let filter = KWidgetModeAvailable | kWidgetModeEnabled
        let mergedPanels = panel.getMergedPanels().filter { $0 != panel }
        let enabledWidgets: [String] = orderedWidgets.flatMap { $0 }
        var mergedWidgetInfos: NSMutableOrderedSet = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Int(filter), panels: mergedPanels)
        var currentWidgetInfos: NSMutableOrderedSet = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Int(filter), panels: [panel])
        var alreadyExist: [String] = []
        for mapWidgetInfo in currentWidgetInfos {
            if let widgetInfo = mapWidgetInfo as? MapWidgetInfo {
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
        mergedWidgetInfos = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Int(filter), panels: mergedPanels)
        currentWidgetInfos = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Int(filter), panels: [panel])
        let defaultWidgetInfos = (widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: 0, panels: panel.getMergedPanels()).array as? [MapWidgetInfo] ?? [])
            .filter { !$0.key.contains(MapWidgetInfo.DELIMITER) }
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
                        mapWidgetInfo = createDuplicateWidget(widgetId: enabledWidget,
                                                              panel: panel,
                                                              widgetsFactory: widgetsFactory,
                                                              selectedAppMode: selectedAppMode)
                        if let newWidgetInfo = mapWidgetInfo {
                            alreadyExist.append(newWidgetInfo.key)
                            needToAdd = true
                        }
                    } else if WidgetType.getById(enabledWidget) != nil {
                        for defaultWidgetInfo in defaultWidgetInfos {
                            if defaultWidgetInfo.key == enabledWidget {
                                mapWidgetInfo = defaultWidgetInfo
                                if let newWidgetInfo = mapWidgetInfo {
                                    alreadyExist.append(newWidgetInfo.key)
                                    needToAdd = true
                                }
                                break
                            }
                        }
                    }
                } else if let widgetInfo = mapWidgetInfo {
                    if !mergedWidgetInfos.contains(widgetInfo), !alreadyExist.contains(widgetInfo.key) {
                        alreadyExist.append(widgetInfo.key)
                        needToAdd = true
                    } else if alreadyExist.contains(widgetInfo.key) || mergedWidgetInfos.contains(widgetInfo) {
                        mapWidgetInfo = createDuplicateWidget(widgetId: WidgetType.getDefaultWidgetId(enabledWidget),
                                                              panel: panel,
                                                              widgetsFactory: widgetsFactory,
                                                              selectedAppMode: selectedAppMode)
                        if let newWidgetInfo = mapWidgetInfo {
                            alreadyExist.append(newWidgetInfo.key)
                            needToAdd = true
                        }
                    }
                }
                if let newWidgetInfo = mapWidgetInfo, needToAdd {
                    newOrder.append(newWidgetInfo.key)
                    if !widgetRegistry.isWidgetVisible(newWidgetInfo.key) {
                        newWidgetInfo.priority = newOrder.firstIndex(of: newWidgetInfo.key) ?? newOrder.count - 1
                        newWidgetInfo.pageIndex = newOrders.firstIndex(of: newOrder) ?? newOrders.count
                        widgetRegistry.getWidgetsFor(panel)?.add(newWidgetInfo)
                        widgetRegistry.enableDisableWidget(for: selectedAppMode,
                                                           widgetInfo: newWidgetInfo,
                                                           enabled: NSNumber(value: true),
                                                           recreateControls: false)
                    }
                }
            }
            if !newOrder.isEmpty {
                newOrders.append(newOrder)
            }
        }
        panel.setWidgetsOrder(pagedOrder: newOrders, appMode: selectedAppMode)
        widgetRegistry.reorderWidgets()
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

}
