//
//  WidgetsSettingsHelper.swift
//  OsmAnd Maps
//
//  Created by Paul on 26.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetsSettingsHelper)
@objcMembers
class WidgetsSettingsHelper: NSObject {

    private let widgetRegistry: OAMapWidgetRegistry
    private let widgetsFactory: MapWidgetsFactory

    private var appMode: OAApplicationMode
    private var settings: OAAppSettings

    init(appMode: OAApplicationMode) {
        self.appMode = appMode
        widgetRegistry = OAMapWidgetRegistry.sharedInstance()
        widgetsFactory = MapWidgetsFactory()
        settings = OAAppSettings.sharedManager()
    }

    func setAppMode(_ appMode: OAApplicationMode) {
        self.appMode = appMode
    }

    func resetConfigureScreenSettings() {
        let allWidgetInfos = widgetRegistry.getWidgetsForPanel(appMode, filterModes: Int(kWidgetModeMatchingPanels), panels: WidgetsPanel.values)
        for widgetInfo in allWidgetInfos! {
            widgetRegistry.enableDisableWidget(for: appMode, widgetInfo: widgetInfo as? MapWidgetInfo, enabled: nil, recreateControls: false)
        }
        settings.mapInfoControls.resetMode(toDefault: appMode)
        settings.customWidgetKeys.resetMode(toDefault: appMode)

        for panel in WidgetsPanel.values {
            panel.getOrderPreference().resetMode(toDefault: appMode)
        }

        settings.transparentMapTheme.resetMode(toDefault: appMode)
        settings.compassMode.resetMode(toDefault: appMode)
        settings.showDistanceRuler.resetMode(toDefault: appMode)
        settings.quickActionIsOn.resetMode(toDefault: appMode)
    }

    func copyConfigureScreenSettings(fromAppMode: OAApplicationMode, widgetParams: [String: Any]) {
        for panel in WidgetsPanel.values {
            copyWidgetsForPanel(fromAppMode: fromAppMode, panel: panel, widgetParams: widgetParams)
        }
        copyPrefFromAppMode(pref: settings.transparentMapTheme, fromAppMode: fromAppMode)
        copyPrefFromAppMode(pref: settings.compassMode, fromAppMode: fromAppMode)
        copyPrefFromAppMode(pref: settings.showDistanceRuler, fromAppMode: fromAppMode)
        copyPrefFromAppMode(pref: settings.quickActionIsOn, fromAppMode: fromAppMode)
    }

    func copyWidgetsForPanel(fromAppMode: OAApplicationMode, panel: WidgetsPanel, widgetParams: [String: Any]? = nil) {
        let filter = kWidgetModeEnabled | KWidgetModeAvailable | kWidgetModeMatchingPanels
        let panels = [panel]
        let widgetInfosToCopy = widgetRegistry.getWidgetsForPanel(fromAppMode, filterModes: Int(filter), panels: panels)

        var previousPage = -1
        var newPagedOrder = [[String]]()
        let defaultWidgetInfos = getDefaultWidgetInfos(panel: panel)

        for widgetInfoToCopy in widgetInfosToCopy! {
            guard let info = widgetInfoToCopy as? MapWidgetInfo, WidgetsAvailabilityHelper.isWidgetAvailable(widgetId: info.key, appMode: appMode) else {
                continue
            }

            let widgetTypeToCopy = info.widget.widgetType
            let duplicateNotPossible = widgetTypeToCopy == nil
            let defaultWidgetId = WidgetType.getDefaultWidgetId(info.key)
            let defaultWidgetInfo = getWidgetInfoById(widgetId: defaultWidgetId, widgetInfos: defaultWidgetInfos)

            if let defaultWidgetInfo = defaultWidgetInfo {
                let widgetIdToAdd: String
                let disabled = !defaultWidgetInfo.isEnabledForAppMode(appMode)
                let inAnotherPanel = defaultWidgetInfo.widgetPanel != panel
                if duplicateNotPossible || (disabled && !inAnotherPanel) {
                    widgetRegistry.enableDisableWidget(for: appMode, widgetInfo: defaultWidgetInfo, enabled:NSNumber(value: true), recreateControls: false)
                    widgetIdToAdd = defaultWidgetInfo.key
                } else {
                    let duplicateWidgetInfo = createDuplicateWidgetInfo(widgetType: widgetTypeToCopy!, panel: panel, widgetParams: widgetParams)
                    widgetIdToAdd = duplicateWidgetInfo != nil ? duplicateWidgetInfo!.key : ""
                }

                if !widgetIdToAdd.isEmpty {
                    if previousPage != info.pageIndex || newPagedOrder.isEmpty {
                        previousPage = info.pageIndex
                        newPagedOrder.append([String]())
                    }
                    newPagedOrder[newPagedOrder.count - 1].append(widgetIdToAdd)
                }
            }
        }
        panel.setWidgetsOrder(pagedOrder: newPagedOrder, appMode: appMode)
    }

    func getWidgetsPagedOrder(fromAppMode: OAApplicationMode, panel: WidgetsPanel, filter: Int) -> [[String]] {
        var previousPage = -1
        let panels = [panel]
        let widgetInfos = widgetRegistry.getWidgetsForPanel(fromAppMode, filterModes: filter, panels: panels)
        var pagedOrder = [[String]]()
        for widgetInfo in widgetInfos! {
            guard let widgetInfo = widgetInfo as? MapWidgetInfo else { continue }
            let widgetId = widgetInfo.key
            if !widgetId.isEmpty && WidgetsAvailabilityHelper.isWidgetAvailable(widgetId: widgetId, appMode: appMode) {
                if previousPage != widgetInfo.pageIndex || pagedOrder.isEmpty {
                    previousPage = widgetInfo.pageIndex
                    pagedOrder.append([String]())
                }
                pagedOrder[pagedOrder.count - 1].append(widgetId)
            }
        }
        return pagedOrder
    }

    private func getDefaultWidgetInfos(panel: WidgetsPanel) -> [MapWidgetInfo] {
        let widgetInfos = widgetRegistry.getWidgetsForPanel(appMode, filterModes: 0, panels: [panel])
        for widgetInfo in widgetInfos! {
            guard let widgetInfo = widgetInfo as? MapWidgetInfo else { continue }
            if widgetInfo.widgetPanel == panel {
                let visibility: NSNumber? = WidgetType.isOriginalWidget(widgetInfo.key) ? NSNumber(value: false) : nil
                widgetRegistry.enableDisableWidget(for: appMode, widgetInfo: widgetInfo, enabled: visibility, recreateControls: false)
            }
        }
        panel.getOrderPreference().resetMode(toDefault: appMode)
        return Array(_immutableCocoaArray: widgetInfos!)
    }

    private func createDuplicateWidgetInfo(widgetType: WidgetType, panel: WidgetsPanel, widgetParams: [String: Any]? = nil) -> MapWidgetInfo? {
        let duplicateWidgetId = WidgetType.getDuplicateWidgetId(widgetType: widgetType)
        let duplicateWidget = widgetsFactory.createMapWidget(customId: duplicateWidgetId, widgetType: widgetType, widgetParams: widgetParams)
        if let duplicateWidget = duplicateWidget {
            let creator = WidgetInfoCreator(appMode: appMode)
            settings.customWidgetKeys.add(duplicateWidgetId, appMode: appMode)
            let duplicateWidgetInfo = creator.createCustomWidgetInfo(widgetId: duplicateWidgetId, widget: duplicateWidget, widgetType: widgetType, panel: panel)
            widgetRegistry.enableDisableWidget(for: appMode, widgetInfo: duplicateWidgetInfo, enabled: NSNumber(value: true), recreateControls: false)
            return duplicateWidgetInfo
        }
        return nil
    }

    private func getWidgetInfoById(widgetId: String, widgetInfos: [MapWidgetInfo]) -> MapWidgetInfo? {
        for widgetInfo in widgetInfos {
            if widgetId == widgetInfo.key {
                return widgetInfo
            }
        }
        return nil
    }

    func resetWidgetsForPanel(panel: WidgetsPanel) {
        let panels = [panel]
        let widgetInfos = widgetRegistry.getWidgetsForPanel(appMode, filterModes: Int(kWidgetModeMatchingPanels), panels: panels)
        for widgetInfo in widgetInfos! {
            guard let widgetInfo = widgetInfo as? MapWidgetInfo else { continue }
            // Disable "false" (not reset "nil"), because visible by default widget should be disabled in non-default panel
            let enabled: NSNumber? = isOriginalWidgetOnAnotherPanel(widgetInfo: widgetInfo) ? NSNumber(value: false) : nil
            widgetRegistry.enableDisableWidget(for: appMode, widgetInfo: widgetInfo, enabled: enabled, recreateControls: false)
        }
        panel.getOrderPreference().resetMode(toDefault: appMode)
    }

    private func isOriginalWidgetOnAnotherPanel(widgetInfo: MapWidgetInfo) -> Bool {
        let original = WidgetType.isOriginalWidget(widgetInfo.key)
        let widgetType = widgetInfo.widget.widgetType
        return original && widgetType != nil && widgetType!.defaultPanel != widgetInfo.widgetPanel
    }

    private func copyPrefFromAppMode(pref: OACommonPreference, fromAppMode: OAApplicationMode) {
        pref.setValueFrom(pref.toStringValue(fromAppMode), appMode: appMode)
    }
}
