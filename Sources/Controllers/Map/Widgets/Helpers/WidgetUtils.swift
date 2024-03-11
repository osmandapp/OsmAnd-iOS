//
//  WidgetUtils.swift
//  OsmAnd Maps
//
//  Created by Skalii on 27.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@objc(OAWidgetUtils)
@objcMembers
final class WidgetUtils: NSObject {

    static func reorderWidgets(orderedWidgetPages: [[String]],
                               panel: WidgetsPanel,
                               selectedAppMode: OAApplicationMode,
                               widgetParams: [String: Any]? = nil) {
        guard let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry else {
            return
        }

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

    static func updateExistingWidgetIds(_ appMode: OAApplicationMode,
                                        panelPreference: OACommonListOfStringList,
                                        newPanelPreference: OACommonListOfStringList?) {
        guard let pages = panelPreference.get(appMode) else { return }
        if newPanelPreference == nil {
            guard (pages.flatMap({ $0 }).contains { WidgetType.oldNewWidgetIds.keys.contains(WidgetType.getDefaultWidgetId($0)) }) else { return }
        }

        var newPages = [Array<String>]()
        for page in pages {
            newPages.append(getUpdatedWidgetIds(page))
        }
        if pages != newPages {
            panelPreference.set(newPages, mode: appMode)
        }
        if let newPanelPreference {
            newPanelPreference.set(newPages, mode: appMode)
        }
    }

    static func updateExistingCustomWidgetIds(_ appMode: OAApplicationMode,
                                              customIdsPreference: OACommonStringList) {
        guard let customIds = customIdsPreference.get(appMode),
              (customIds.contains { WidgetType.oldNewWidgetIds.keys.contains(WidgetType.getDefaultWidgetId($0)) }) else { return }

        let newCustomIds = Self.getUpdatedWidgetIds(customIds)
        if customIds != newCustomIds {
            customIdsPreference.set(newCustomIds, mode: appMode)
        }
    }
    
    static func updateExistingWidgetsVisibility(_ appMode: OAApplicationMode,
                                                visibilityPreference: OACommonString) {
        guard let widgetsVisibilityString = visibilityPreference.get(appMode) else { return  }

        let widgetsVisibility = widgetsVisibilityString.components(separatedBy: SETTINGS_SEPARATOR);
        guard (widgetsVisibility.contains { WidgetType.oldNewWidgetIds.keys.contains(WidgetType.getDefaultWidgetId($0)) }) else { return }

        let newWidgetsVisibility = Self.getUpdatedWidgetIds(widgetsVisibility)
        if widgetsVisibility != newWidgetsVisibility {
            visibilityPreference.set(newWidgetsVisibility.joined(separator: SETTINGS_SEPARATOR), mode: appMode)
        }
    }

    static func getUpdatedWidgetIds(_ widgetIds: [String]) -> [String] {
        var newWidgetsList = [String]()
        for widgetId in widgetIds {
            let originalId = WidgetType.getDefaultWidgetId(widgetId)
            if let newId = WidgetType.oldNewWidgetIds[originalId], !newId.isEmpty {
                newWidgetsList.append(widgetId.replacingOccurrences(of: originalId, with: newId))
            } else {
                newWidgetsList.append(widgetId)
            }
            
        }
        return newWidgetsList
    }
}
