//
//  WidgetUtils.swift
//  OsmAnd Maps
//
//  Created by Skalii on 27.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@objcMembers
final class WidgetUtils: NSObject {
    static func createWidget(widgetId: String,
                             panel: WidgetsPanel,
                             widgetsFactory: MapWidgetsFactory,
                             selectedAppMode: OAApplicationMode,
                             screenLayoutMode: ScreenLayoutMode,
                             widgetParams: [String: Any]? = nil) -> MapWidgetInfo? {
        guard let widgetType = WidgetType.getById(widgetId) else {
            return nil
        }
        let id = widgetId.contains(MapWidgetInfo.DELIMITER) ? widgetId : WidgetType.getDuplicateWidgetId(widgetId)
        guard let widget = widgetsFactory.createMapWidget(customId: id, widgetType: widgetType, widgetParams: widgetParams) else {
            return nil
        }
        let creator = WidgetInfoCreator(appMode: selectedAppMode, screenLayoutMode: screenLayoutMode)
        return creator.createCustomWidgetInfo(widgetId: id,
                                              widget: widget,
                                              widgetType: widgetType,
                                              panel: panel)
    }
    
    static func createNewWidgets(widgetsIds: [String],
                                 panel: WidgetsPanel,
                                 appMode: OAApplicationMode,
                                 screenLayoutMode: ScreenLayoutMode,
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
                                             screenLayoutMode: screenLayoutMode,
                                             widgetParams: widgetParams) {
                createNewWidget(widgetInfo,
                                panel: panel,
                                appMode: appMode,
                                screenLayoutMode: screenLayoutMode,
                                recreateControls: false,
                                selectedWidget: selectedWidget,
                                addToNext: addToNext)
                resultWidgetsInfos.append(widgetInfo)
            }
        }
        widgetRegistry.reorderWidgets()
        OARootViewController.instance().mapPanel.recreateControls()
        return resultWidgetsInfos
    }

    static func createNewWidget(_ widgetInfo: MapWidgetInfo,
                                panel: WidgetsPanel,
                                appMode: OAApplicationMode,
                                screenLayoutMode: ScreenLayoutMode,
                                recreateControls: Bool,
                                selectedWidget: String? = nil,
                                addToNext: Bool? = nil) {
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
        let settings = OAAppSettings.sharedManager()
        let screenElementsMode = ScreenElementsMode(usesSeparateLayouts: settings.useSeparateLayouts.get(appMode))
        settings.customWidgetKeys(screenLayoutMode.rawValue,
                                  screenElementsMode: screenElementsMode.rawValue).add(widgetInfo.key,
                                                                                      appMode: appMode) // todo
        if let selectedWidget, let addToNext {
            addWidgetToSpecificPlace(with: widgetInfo,
                                     widgetsPanel: panel,
                                     selectedAppMode: appMode,
                                     screenLayoutMode: screenLayoutMode,
                                     selectedWidget: selectedWidget,
                                     addToNext: addToNext)
        } else {
            addWidgetToEnd(with: widgetInfo,
                           widgetsPanel: panel,
                           selectedAppMode: appMode,
                           screenLayoutMode: screenLayoutMode)
        }
        widgetRegistry.enableDisableWidget(for: appMode,
                                           widgetInfo: widgetInfo,
                                           enabled: true,
                                           recreateControls: false)
        if recreateControls {
            OARootViewController.instance().mapPanel.recreateControls()
        }
    }
    
    private static func addWidgetToEnd(with targetWidget: MapWidgetInfo,
                                       widgetsPanel: WidgetsPanel,
                                       selectedAppMode: OAApplicationMode,
                                       screenLayoutMode: ScreenLayoutMode) {
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
        var pagedOrder: [Int: [String]] = [:]
        let enabledWidgets = widgetRegistry.widgets(forPanel: selectedAppMode,
                                                    filterModes: Int(kWidgetModeEnabled | kWidgetModeMatchingPanels),
                                                    panels: [widgetsPanel],
                                                    layoutMode: OAAppSettings.sharedManager().useSeparateLayouts.get(selectedAppMode)
                                                        ? NSNumber(value: screenLayoutMode.rawValue)
                                                        : nil)
        
        widgetRegistry.widgets(for: targetWidget.widgetPanel).remove(targetWidget)
        
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
            widgetRegistry.widgets(for: targetWidget.widgetPanel).add(targetWidget)
            
            var flatOrder: [[String]] = []
            flatOrder.append([targetWidget.key])
            widgetsPanel.setWidgetsOrder(pagedOrder: flatOrder, appMode: selectedAppMode, screenLayoutMode: screenLayoutMode)
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
                    
                    if let previousLastVisibleWidgetInfo = sortedWidgets.first(where: { $0.key == previousLastWidgetId }) {
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
            widgetRegistry.widgets(for: widgetsPanel).add(targetWidget)
            widgetsPanel.setWidgetsOrder(pagedOrder: orders, appMode: selectedAppMode, screenLayoutMode: screenLayoutMode)
        }
    }
    
    private static func addWidgetToSpecificPlace(with targetWidget: MapWidgetInfo,
                                                 widgetsPanel: WidgetsPanel,
                                                 selectedAppMode: OAApplicationMode,
                                                 screenLayoutMode: ScreenLayoutMode,
                                                 selectedWidget: String,
                                                 addToNext: Bool) {
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
        var pagedOrder = [Int: [String]]()
        
        let enabledWidgets = widgetRegistry.widgets(forPanel: selectedAppMode,
                                                    filterModes: Int(kWidgetModeEnabled | kWidgetModeMatchingPanels),
                                                    panels: [widgetsPanel],
                                                    layoutMode: OAAppSettings.sharedManager().useSeparateLayouts.get(selectedAppMode)
                                                        ? NSNumber(value: screenLayoutMode.rawValue)
                                                        : nil)
        let sortedWidgets = (enabledWidgets!.array as! [MapWidgetInfo]).sorted { $0.priority < $1.priority }
        
        widgetRegistry.widgets(for: targetWidget.widgetPanel).remove(targetWidget)
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
            widgetRegistry.widgets(for: widgetsPanel).add(targetWidget)
            
            var flatOrder = [[String]]()
            flatOrder.append([targetWidget.key])
            widgetsPanel.setWidgetsOrder(pagedOrder: flatOrder, appMode: selectedAppMode, screenLayoutMode: screenLayoutMode)
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
                if let widgetInfo = sortedWidgets.first(where: { $0.key == widgetId }) {
                    widgetInfo.pageIndex = insertPage
                    widgetInfo.priority = index
                } else if widgetId == targetWidget.key {
                    targetWidget.pageIndex = insertPage
                    targetWidget.priority = index
                }
            }
            orders[insertPage] = pageToAddWidget
            
            widgetRegistry.widgets(for: widgetsPanel).add(targetWidget)
            widgetsPanel.setWidgetsOrder(pagedOrder: orders, appMode: selectedAppMode, screenLayoutMode: screenLayoutMode)
        }
    }
    
    private static func getNewNextPageIndex(pages: [Int]) -> Int {
        pages.max() ?? 0
    }
}

extension WidgetUtils {
    static func applyMostFrequentStyleForPagedWidgets(appMode: OAApplicationMode,
                                                      filterModes: Int,
                                                      panels: [WidgetsPanel] = [WidgetsPanel.topPanel, WidgetsPanel.bottomPanel]) {
        for panel in panels {
            let pagedWidgets: [[MapWidgetInfo]] = OAMapWidgetRegistry.sharedInstance()
                .pagedWidgets(forPanel: appMode,
                              panel: panel,
                              filterModes: filterModes)
                .compactMap { $0.array as? [MapWidgetInfo] }
            
            for pageWidgets in pagedWidgets {
                let textWidgets = pageWidgets.compactMap { $0.widget as? OATextInfoWidget }
                guard textWidgets.count > 1 else { continue }
                textWidgets.updateWithMostFrequentStyle(with: appMode)
            }
        }
    }
}

extension WidgetUtils {
    static func deleteWidgetAlert(with appMode: OAApplicationMode, widgetInfo: MapWidgetInfo, completion: (() -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: localizedString("delete_widget"),
                                      message: localizedString("delete_widget_description"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { _ in
            let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
            widgetRegistry.enableDisableWidget(for: appMode, widgetInfo: widgetInfo, enabled: false, recreateControls: true)
            completion?()
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        return alert
    }
}
