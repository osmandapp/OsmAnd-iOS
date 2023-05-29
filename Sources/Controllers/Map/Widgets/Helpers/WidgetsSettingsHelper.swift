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
        widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
        widgetsFactory = MapWidgetsFactory()
        settings = OAAppSettings.sharedManager()
    }

    func setAppMode(_ appMode: OAApplicationMode) {
        self.appMode = appMode
    }

    func resetConfigureScreenSettings() {
        let allWidgetInfos = widgetRegistry.getWidgetsForPanel(appMode, filterModes: 0, panels: WidgetsPanel.values)
        for widgetInfo in allWidgetInfos {
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

    func copyConfigureScreenSettings(from appMode: OAApplicationMode) {
        for panel in WidgetsPanel.values {
            copyWidgetsForPanel(from: appMode, panel: panel)
        }
        copyPrefFromAppMode(pref: settings.transparentMapTheme, from: appMode)
        copyPrefFromAppMode(pref: settings.compassMode, from: appMode)
        copyPrefFromAppMode(pref: settings.showDistanceRuler, from: appMode)
        copyPrefFromAppMode(pref: settings.quickActionIsOn, from: appMode)
    }

    func copyWidgetsForPanel(from appMode: OAApplicationMode, panel: WidgetsPanel) {
        let filter = kWidgetModeEnabled | KWidgetModeAvailable
        let panels = [panel]
        let widgetInfosToCopy = widgetRegistry.getWidgetsForPanel(appMode, filterModes: Int(filter), panels: panels)

        var previousPage = -1
        var newPagedOrder = [[String]]()
        let defaultWidgetInfos = getDefaultWidgetInfos(panel: panel)

        for widgetInfoToCopy in widgetInfosToCopy {
            guard let info = widgetInfoToCopy as? MapWidgetInfo, WidgetsAvailabilityHelper.isWidgetAvailable(widgetId: info.key, appMode: appMode) else {
                continue
            }

            let widgetTypeToCopy = info.widget.widgetType
            let duplicateNotPossible = widgetTypeToCopy == nil || !panel.isDuplicatesAllowed()
            let defaultWidgetId = WidgetType.getDefaultWidgetId(widgetInfoToCopy.key)
            let defaultWidgetInfo = getWidgetInfoById(widgetId: defaultWidgetId, widgetInfos: defaultWidgetInfos)

            if let defaultWidgetInfo = defaultWidgetInfo {
                let widgetIdToAdd: String
                let disabled = !defaultWidgetInfo.isEnabledForAppMode(appMode: appMode)
                let inAnotherPanel = defaultWidgetInfo.widgetPanel != panel
                if duplicateNotPossible || (disabled && !inAnotherPanel) {
                    widgetRegistry.enableDisableWidgetForMode(appMode: appMode, widgetInfo: defaultWidgetInfo, visibility: true, reset: false)
                    widgetIdToAdd = defaultWidgetInfo.key
                } else {
                    let duplicateWidgetInfo = createDuplicateWidgetInfo(widgetType: widgetTypeToCopy, panel: panel)
                    widgetIdToAdd = duplicateWidgetInfo != nil ? duplicateWidgetInfo!.key : ""
                }

                if !widgetIdToAdd.isEmpty {
                    if previousPage != widgetInfoToCopy.pageIndex || newPagedOrder.isEmpty {
                        previousPage = widgetInfoToCopy.pageIndex
                        newPagedOrder.append([String]())
                    }
                    newPagedOrder[newPagedOrder.count - 1].append(widgetIdToAdd)
                }
            }
        }
        panel.setWidgetsOrder(appMode: appMode, newPagedOrder: newPagedOrder, settings: settings)
    }

    func getWidgetsPagedOrder(from appMode: ApplicationMode, panel: WidgetsPanel, filter: Int) -> [[String]] {
        var previousPage = -1
        let panels = [panel]
        let widgetInfos = widgetRegistry.getWidgetsForPanel(mapActivity: mapActivity, appMode: fromAppMode, filter: filter, panels: panels)
        var pagedOrder = [[String]]()
        for widgetInfo in widgetInfos {
            let widgetId = widgetInfo.key
            if !widgetId.isEmpty && WidgetsAvailabilityHelper.isWidgetAvailable(app: app, widgetId: widgetId, appMode: appMode) {
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
        let widgetInfos = widgetRegistry.getWidgetsForPanel(mapActivity: mapActivity, appMode: appMode, filter: 0, panels: panel.getMergedPanels())
        for widgetInfo in widgetInfos {
            if widgetInfo.widgetPanel == panel {
                let visibility: Bool? = WidgetType.isOriginalWidget(widgetInfo.key) ? false : nil
                widgetRegistry.enableDisableWidgetForMode(appMode: appMode, widgetInfo: widgetInfo, visibility: visibility, reset: false)
            }
        }
        panel.getOrderPreference(settings: settings).resetModeToDefault(appMode: appMode)
        return Array(widgetInfos)
    }

    private func createDuplicateWidgetInfo(widgetType: WidgetType, panel: WidgetsPanel) -> MapWidgetInfo? {
        let duplicateWidgetId = WidgetType.getDuplicateWidgetId(widgetType: widgetType)
        let duplicateWidget = widgetsFactory.createMapWidget(duplicateWidgetId: duplicateWidgetId, widgetType: widgetType)
        if let duplicateWidget = duplicateWidget {
            let creator = WidgetInfoCreator(app: app, appMode: appMode)
            settings.CUSTOM_WIDGETS_KEYS.addModeValue(appMode: appMode, value: duplicateWidgetId)
            let duplicateWidgetInfo = creator.createCustomWidgetInfo(duplicateWidgetId: duplicateWidgetId, duplicateWidget: duplicateWidget, widgetType: widgetType, panel: panel)
            widgetRegistry.enableDisableWidgetForMode(appMode: appMode, widgetInfo: duplicateWidgetInfo, visibility: true, reset: false)
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
        let widgetInfos = widgetRegistry.getWidgetsForPanel(mapActivity: mapActivity, appMode: appMode, filter: 0, panels: panels)
        for widgetInfo in widgetInfos {
            // Disable "false" (not reset "nil"), because visible by default widget should be disabled in non-default panel
            let enabled = isOriginalWidgetOnAnotherPanel(widgetInfo: widgetInfo) ? false : nil
            widgetRegistry.enableDisableWidgetForMode(appMode: appMode, widgetInfo: widgetInfo, visibility: enabled, reset: false)
        }
        panel.getOrderPreference(settings: settings).resetModeToDefault(appMode: appMode)
    }

    private func isOriginalWidgetOnAnotherPanel(widgetInfo: MapWidgetInfo) -> Bool {
        let original = WidgetType.isOriginalWidget(widgetInfo.key)
        let widgetType = widgetInfo.widget.getWidgetType()
        return original && widgetType != nil && widgetType!.defaultPanel != widgetInfo.widgetPanel
    }

    private func copyPrefFromAppMode<T>(pref: OsmandPreference<T>, from appMode: ApplicationMode) {
        pref.setModeValue(appMode: appMode, value: pref.getModeValue(appMode: appMode))
    }
}
