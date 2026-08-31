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
    private var layoutMode: ScreenLayoutMode
    private let settings: OAAppSettings
    private let mapButtonsHelper: OAMapButtonsHelper

    init(appMode: OAApplicationMode, layoutMode: ScreenLayoutMode) {
        self.appMode = appMode
        self.layoutMode = layoutMode
        widgetRegistry = OAMapWidgetRegistry.sharedInstance()
        widgetsFactory = MapWidgetsFactory()
        settings = OAAppSettings.sharedManager()
        mapButtonsHelper = OAMapButtonsHelper.sharedInstance()
    }

    func setAppMode(_ appMode: OAApplicationMode) {
        self.appMode = appMode
    }

    func setLayoutMode(_ layoutMode: ScreenLayoutMode) {
        self.layoutMode = layoutMode
    }

    func resetConfigureScreenSettings() {
        OAAppSettings.performBatchedPreferenceNotifications { [self] in
            let screenElementsMode = ScreenElementsMode(usesSeparateLayouts: settings.useSeparateLayouts.get(appMode))
            let allWidgetInfos = widgetRegistry.widgets(forPanel: appMode,
                                                        filterModes: Int(kWidgetModeMatchingPanels),
                                                        panels: WidgetsPanel.values,
                                                        screenLayoutMode: layoutMode.rawValue)
            for widgetInfo in allWidgetInfos! {
                widgetRegistry.enableDisableWidget(for: appMode,
                                                   widgetInfo: widgetInfo as? MapWidgetInfo,
                                                   enabled: nil,
                                                   recreateControls: false)
            }
            resetWidgetPreferences(screenElementsMode)

            ScreenElementsMode.allCases.forEach {
                settings.panelsLayoutMode(layoutMode.rawValue,
                                          screenElementsMode: $0.rawValue).resetMode(toDefault: appMode)
            }
            settings.useSeparateLayouts.resetMode(toDefault: appMode)
            settings.transparentWidgets(layoutMode.rawValue,
                                        screenElementsMode: screenElementsMode.rawValue).resetMode(toDefault: appMode)
            settings.showDistanceRuler.resetMode(toDefault: appMode)
            settings.distanceByTapTextSize.resetMode(toDefault: appMode)
            settings.positionPlacementOnMap.resetMode(toDefault: appMode)
            settings.showSpeedometer.resetMode(toDefault: appMode)
            settings.speedometerSize.resetMode(toDefault: appMode)
            settings.showSpeedLimitWarning.resetMode(toDefault: appMode)

            for buttonState in mapButtonsHelper.getDefaultButtonsStates() {
                buttonState.resetForMode(appMode)
            }
            mapButtonsHelper.resetQuickActions(for: appMode)
            mapButtonsHelper.getDefaultSizePref().resetMode(toDefault: appMode)
            mapButtonsHelper.getDefaultOpacityPref().resetMode(toDefault: appMode)
            mapButtonsHelper.getDefaultCornerRadiusPref().resetMode(toDefault: appMode)
            mapButtonsHelper.getDefaultGlassStylePref().resetMode(toDefault: appMode)
        }
    }

    func copyConfigureScreenSettings(fromAppMode: OAApplicationMode, widgetParams: [String: Any]) {
        OAAppSettings.performBatchedPreferenceNotifications { [self] in
            copyPrefFromAppMode(pref: settings.useSeparateLayouts, fromAppMode: fromAppMode)
            ScreenElementsMode.allCases.forEach {
                copyWidgetsForAllPanels(fromAppMode: fromAppMode,
                                        screenElementsMode: $0,
                                        widgetParams: widgetParams)
                copyPrefFromAppMode(pref: settings.panelsLayoutMode(layoutMode.rawValue,
                                                                   screenElementsMode: $0.rawValue),
                                    fromAppMode: fromAppMode)
                copyPrefFromAppMode(pref: settings.transparentWidgets(layoutMode.rawValue,
                                                                      screenElementsMode: $0.rawValue),
                                    fromAppMode: fromAppMode)
            }
            copyPrefFromAppMode(pref: settings.showDistanceRuler, fromAppMode: fromAppMode)
            copyPrefFromAppMode(pref: settings.distanceByTapTextSize, fromAppMode: fromAppMode)
            copyPrefFromAppMode(pref: settings.positionPlacementOnMap, fromAppMode: fromAppMode)
            copyPrefFromAppMode(pref: settings.showSpeedometer, fromAppMode: fromAppMode)
            copyPrefFromAppMode(pref: settings.speedometerSize, fromAppMode: fromAppMode)
            copyPrefFromAppMode(pref: settings.showSpeedLimitWarning, fromAppMode: fromAppMode)
            copyPrefFromAppMode(pref: mapButtonsHelper.getDefaultSizePref(), fromAppMode: fromAppMode)
            copyPrefFromAppMode(pref: mapButtonsHelper.getDefaultOpacityPref(), fromAppMode: fromAppMode)
            copyPrefFromAppMode(pref: mapButtonsHelper.getDefaultCornerRadiusPref(), fromAppMode: fromAppMode)
            copyPrefFromAppMode(pref: mapButtonsHelper.getDefaultGlassStylePref(), fromAppMode: fromAppMode)

            for buttonState in mapButtonsHelper.getDefaultButtonsStates() {
                buttonState.copyForMode(from: fromAppMode, to: appMode)
            }
            mapButtonsHelper.copyQuickActions(from: appMode, fromAppMode: fromAppMode)
        }
    }

    func copyWidgetsForPanel(fromAppMode: OAApplicationMode,
                             fromLayoutMode: ScreenLayoutMode? = nil,
                             panel: WidgetsPanel,
                             widgetParams: [String: Any]? = nil) {
        OAAppSettings.performBatchedPreferenceNotifications { [self] in
            let screenElementsMode = ScreenElementsMode(usesSeparateLayouts: settings.useSeparateLayouts.get(appMode))
            copyWidgetsForPanel(fromAppMode: fromAppMode,
                                fromLayoutMode: fromLayoutMode ?? layoutMode,
                                screenElementsMode: screenElementsMode,
                                panel: panel,
                                widgetParams: widgetParams)
        }
    }

    private func copyWidgetsForPanel(fromAppMode: OAApplicationMode,
                                     fromLayoutMode: ScreenLayoutMode,
                                     screenElementsMode: ScreenElementsMode,
                                     panel: WidgetsPanel,
                                     widgetParams: [String: Any]?) {
        let filter = kWidgetModeEnabled | KWidgetModeAvailable | kWidgetModeMatchingPanels
        var previousPage = -1
        var newPagedOrder = [[String]]()
        let defaultWidgetInfos = defaultWidgetInfos(panel: panel,
                                                    screenElementsMode: screenElementsMode)
        let visibilityLayoutMode = screenElementsMode == .independent // todo
            ? NSNumber(value: layoutMode.rawValue)
            : nil
        let widgetsVisibility = MapWidgetInfo.widgetsVisibility(appMode,
                                                                screenLayoutMode: visibilityLayoutMode)

        if let widgetInfosToCopy = widgetRegistry.widgets(forPanel: fromAppMode,
                                                          filterModes: Int(filter),
                                                          panels: [panel],
                                                          screenLayoutMode: fromLayoutMode.rawValue,
                                                          screenElementsMode: screenElementsMode.rawValue) {
            for widgetInfoToCopy in widgetInfosToCopy {
                guard let info = widgetInfoToCopy as? MapWidgetInfo,
                      WidgetsAvailabilityHelper.isWidgetAvailable(widgetId: info.key, appMode: appMode) else {
                    continue
                }

                let widgetTypeToCopy = info.widget.widgetType
                let duplicateNotPossible = widgetTypeToCopy == nil
                let defaultWidgetId = WidgetType.getDefaultWidgetId(info.key)
                let defaultWidgetInfo = getWidgetInfoById(widgetId: defaultWidgetId,
                                                          widgetInfos: defaultWidgetInfos)

                if let defaultWidgetInfo = defaultWidgetInfo {
                    let widgetIdToAdd: String
                    let disabled = !defaultWidgetInfo.isEnabledForAppMode(appMode,
                                                                          widgetsVisibility: widgetsVisibility)
                    let inAnotherPanel = defaultWidgetInfo.widgetPanel != panel
                    if duplicateNotPossible || (disabled && !inAnotherPanel) {
                        enableDisableWidget(defaultWidgetInfo,
                                            enabled: NSNumber(value: true),
                                            screenElementsMode: screenElementsMode)
                        widgetIdToAdd = defaultWidgetInfo.key
                    } else {
                        let duplicateWidgetInfo = createDuplicateWidgetInfo(widgetType: widgetTypeToCopy!,
                                                                            panel: panel,
                                                                            screenElementsMode: screenElementsMode,
                                                                            widgetParams: widgetParams)
                        widgetIdToAdd = duplicateWidgetInfo != nil ? duplicateWidgetInfo!.key : ""
                    }

                    if !widgetIdToAdd.isEmpty {
                        let customId = widgetIdToAdd == defaultWidgetInfo.key ? nil : widgetIdToAdd
                        info.widget.copySettings(from: fromAppMode,
                                                 appMode: appMode,
                                                 customId: customId)
                        if previousPage != info.pageIndex || newPagedOrder.isEmpty {
                            previousPage = info.pageIndex
                            newPagedOrder.append([String]())
                        }
                        newPagedOrder[newPagedOrder.count - 1].append(widgetIdToAdd)
                    }
                }
            }
        }
        panel.setWidgetsOrder(pagedOrder: newPagedOrder,
                              appMode: appMode,
                              screenLayoutMode: layoutMode,
                              screenElementsMode: screenElementsMode)
    }

    func getWidgetsPagedOrder(fromAppMode: OAApplicationMode, panel: WidgetsPanel, filter: Int) -> [[String]] {
        var previousPage = -1
        let panels = [panel]
        var pagedOrder = [[String]]()
        if let widgetInfos = widgetRegistry.widgets(forPanel: fromAppMode,
                                                    filterModes: filter,
                                                    panels: panels,
                                                    screenLayoutMode: layoutMode.rawValue) {
            for widgetInfo in widgetInfos {
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
        }
        return pagedOrder
    }

    private func defaultWidgetInfos(panel: WidgetsPanel,
                                    screenElementsMode: ScreenElementsMode) -> [MapWidgetInfo] {
        let widgetInfos = widgetRegistry.widgets(forPanel: appMode,
                                                 filterModes: 0,
                                                 panels: [panel],
                                                 screenLayoutMode: layoutMode.rawValue,
                                                 screenElementsMode: screenElementsMode.rawValue)
        if let widgetInfos {
            for widgetInfo in widgetInfos {
                guard let widgetInfo = widgetInfo as? MapWidgetInfo else { continue }
                if widgetInfo.widgetPanel == panel {
                    let visibility: NSNumber? = WidgetType.isOriginalWidget(widgetInfo.key) ? NSNumber(value: false) : nil
                    enableDisableWidget(widgetInfo,
                                        enabled: visibility,
                                        screenElementsMode: screenElementsMode)
                }
            }
        }
        panel.orderPreference(screenLayoutMode: layoutMode,
                              screenElementsMode: screenElementsMode,
                              appMode: appMode).resetMode(toDefault: appMode)
        return widgetInfos.flatMap { Array(_immutableCocoaArray: $0) } ?? []
    }

    private func createDuplicateWidgetInfo(widgetType: WidgetType,
                                           panel: WidgetsPanel,
                                           screenElementsMode: ScreenElementsMode,
                                           widgetParams: [String: Any]? = nil) -> MapWidgetInfo? {
        let duplicateWidgetId = WidgetType.getDuplicateWidgetId(widgetType: widgetType)
        let duplicateWidget = widgetsFactory.createMapWidget(customId: duplicateWidgetId, widgetType: widgetType, widgetParams: widgetParams)
        if let duplicateWidget {
            let creator = WidgetInfoCreator(appMode: appMode, screenLayoutMode: layoutMode)
            settings.customWidgetKeys(layoutMode.rawValue,
                                      screenElementsMode: screenElementsMode.rawValue).add(duplicateWidgetId,
                                                                                          appMode: appMode)
            let duplicateWidgetInfo = creator.createCustomWidgetInfo(widgetId: duplicateWidgetId, widget: duplicateWidget, widgetType: widgetType, panel: panel)
            enableDisableWidget(duplicateWidgetInfo,
                                enabled: NSNumber(value: true),
                                screenElementsMode: screenElementsMode)
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
        OAAppSettings.performBatchedPreferenceNotifications { [self] in
            let panels = [panel]
            let widgetInfos = widgetRegistry.widgets(forPanel: appMode,
                                                     filterModes: Int(kWidgetModeMatchingPanels),
                                                     panels: panels,
                                                     screenLayoutMode: layoutMode.rawValue)
            for widgetInfo in widgetInfos! {
                guard let widgetInfo = widgetInfo as? MapWidgetInfo else { continue }
                if WidgetType.isOriginalWidget(widgetInfo.key)
                    && WidgetsAvailabilityHelper.isWidgetVisibleByDefault(widgetId: widgetInfo.key,
                                                                          appMode: appMode) {
                    widgetRegistry.enableDisableWidget(for: appMode,
                                                       widgetInfo: widgetInfo,
                                                       enabled: true,
                                                       recreateControls: false)
                } else {
                    // Disable "false" (not reset "nil"), because visible by default widget should be disabled in non-default panel
                    let enabled: NSNumber? = isOriginalWidgetOnAnotherPanel(widgetInfo: widgetInfo)
                        ? NSNumber(value: false)
                        : nil
                    widgetRegistry.enableDisableWidget(for: appMode,
                                                       widgetInfo: widgetInfo,
                                                       enabled: enabled,
                                                       recreateControls: false)
                }
            }
            panel.orderPreference(screenLayoutMode: layoutMode,
                                  appMode: appMode).resetMode(toDefault: appMode)
        }
    }

    private func isOriginalWidgetOnAnotherPanel(widgetInfo: MapWidgetInfo) -> Bool {
        let original = WidgetType.isOriginalWidget(widgetInfo.key)
        let widgetType = widgetInfo.widget.widgetType
        return original && widgetType != nil && widgetType!.defaultPanel != widgetInfo.widgetPanel
    }

    private func copyPrefFromAppMode(pref: OACommonPreference, fromAppMode: OAApplicationMode) {
        pref.setValueFrom(pref.toStringValue(fromAppMode), appMode: appMode)
    }

    private func copyWidgetsForAllPanels(fromAppMode: OAApplicationMode,
                                         screenElementsMode: ScreenElementsMode,
                                         widgetParams: [String: Any]) {
        resetWidgetPreferences(screenElementsMode)
        for panel in WidgetsPanel.values {
            copyWidgetsForPanel(fromAppMode: fromAppMode,
                                fromLayoutMode: layoutMode,
                                screenElementsMode: screenElementsMode,
                                panel: panel,
                                widgetParams: widgetParams)
        }
    }

    private func enableDisableWidget(_ widgetInfo: MapWidgetInfo,
                                     enabled: NSNumber?,
                                     screenElementsMode: ScreenElementsMode) {
        let currentScreenElementsMode = ScreenElementsMode(usesSeparateLayouts: settings.useSeparateLayouts.get(appMode))
        if screenElementsMode == currentScreenElementsMode {
            widgetRegistry.enableDisableWidget(for: appMode,
                                               widgetInfo: widgetInfo,
                                               enabled: enabled,
                                               recreateControls: false)
        } else {
            let visibilityLayoutMode = screenElementsMode == .independent // todo
                ? NSNumber(value: layoutMode.rawValue)
                : nil
            widgetInfo.enableDisableForMode(appMode,
                                            enabled: enabled,
                                            screenLayoutMode: visibilityLayoutMode)
        }
    }

    private func resetWidgetPreferences(_ screenElementsMode: ScreenElementsMode) {
        settings.mapInfoControls(layoutMode.rawValue,
                                 screenElementsMode: screenElementsMode.rawValue).resetMode(toDefault: appMode)
        settings.customWidgetKeys(layoutMode.rawValue,
                                  screenElementsMode: screenElementsMode.rawValue).resetMode(toDefault: appMode)
        for panel in WidgetsPanel.values {
            settings.widgetPanelOrder(panel,
                                      screenLayoutMode: layoutMode.rawValue,
                                      screenElementsMode: screenElementsMode.rawValue).resetMode(toDefault: appMode)
        }
    }
}
