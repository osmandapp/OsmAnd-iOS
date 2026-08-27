//
//  WidgetsPanel.swift
//  OsmAnd Maps
//
//  Created by Paul on 28.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetsPanel)
@objcMembers
class WidgetsPanel: NSObject, NSCopying {
    
    static let leftPanel = WidgetsPanel("ic_custom_screen_side_left",
                                       landscapeIconName: "ic_custom_screen_side_left_landscape",
                                       title: localizedString("map_widget_left"))
    static let rightPanel = WidgetsPanel("ic_custom_screen_side_right",
                                        landscapeIconName: "ic_custom_screen_side_right_landscape",
                                        title: localizedString("map_widget_right"))
    static let topPanel = WidgetsPanel("ic_custom_screen_side_top",
                                      landscapeIconName: "ic_custom_screen_side_top_landscape",
                                      title: localizedString("top_widgets_panel"))
    static let bottomPanel = WidgetsPanel("ic_custom_screen_side_bottom",
                                         landscapeIconName: "ic_custom_screen_side_bottom_landscape",
                                         title: localizedString("bottom_widgets_panel"))
    
    static let values: [WidgetsPanel] = [.leftPanel, .rightPanel, .topPanel, .bottomPanel]
    
    static let DEFAULT_ORDER = 1000
    private static func getOrderIds(_ panel: WidgetsPanel) -> [String] {
        return WidgetType.values.reduce(into: [String]()) { result, type in
            let id = type.id
            let defaultPanel = type.defaultPanel
            if defaultPanel == panel {
                result.append(id)
            }
        }
    }

    private static var ORIGINAL_LEFT_ORDER = getOrderIds(.leftPanel)
    private static var ORIGINAL_RIGHT_ORDER = getOrderIds(.rightPanel)
    private static var ORIGINAL_TOP_ORDER = getOrderIds(.topPanel)
    private static var ORIGINAL_BOTTOM_ORDER = getOrderIds(.bottomPanel)
    
    let title: String
    let iconName: String
    let landscapeIconName: String

    var isPanelVertical: Bool {
        self == .topPanel || self == .bottomPanel
    }

    internal required init(_ iconName: String, landscapeIconName: String, title: String) {
        self.title = title
        self.iconName = iconName
        self.landscapeIconName = landscapeIconName
    }

    func iconName(for screenLayoutMode: ScreenLayoutMode) -> String {
        screenLayoutMode.isPortrait ? iconName : landscapeIconName
    }

    func getOriginalOrder() -> [String] {
        if self == .leftPanel {
            return WidgetsPanel.ORIGINAL_LEFT_ORDER
        } else if self == .rightPanel {
            return WidgetsPanel.ORIGINAL_RIGHT_ORDER
        } else if self == .topPanel {
            return WidgetsPanel.ORIGINAL_TOP_ORDER
        } else {
            return WidgetsPanel.ORIGINAL_BOTTOM_ORDER
        }
    }

    func getOriginalWidgetOrder(widgetId: String) -> Int {
        let order = getOriginalOrder().firstIndex(of: widgetId)
        return order ?? WidgetsPanel.DEFAULT_ORDER
    }
    
    func widgetPage(_ widgetId: String, appMode: OAApplicationMode, screenLayoutMode: ScreenLayoutMode) -> Int {
        pagedOrder(widgetId, appMode: appMode, screenLayoutMode: screenLayoutMode).0
    }

    func widgetPage(_ widgetId: String,
                    appMode: OAApplicationMode,
                    screenLayoutMode: ScreenLayoutMode,
                    screenElementsMode: ScreenElementsMode) -> Int {
        pagedOrder(widgetId,
                   appMode: appMode,
                   screenLayoutMode: screenLayoutMode,
                   screenElementsMode: screenElementsMode).0
    }
    
    func widgetOrder(_ widgetId: String, appMode: OAApplicationMode, screenLayoutMode: ScreenLayoutMode) -> Int {
        pagedOrder(widgetId, appMode: appMode, screenLayoutMode: screenLayoutMode).1
    }

    func widgetOrder(_ widgetId: String,
                     appMode: OAApplicationMode,
                     screenLayoutMode: ScreenLayoutMode,
                     screenElementsMode: ScreenElementsMode) -> Int {
        pagedOrder(widgetId,
                   appMode: appMode,
                   screenLayoutMode: screenLayoutMode,
                   screenElementsMode: screenElementsMode).1
    }
    
    private func getRtlPanel(rtl: Bool) -> WidgetsPanel {
        if !rtl || self == .topPanel || self == .bottomPanel {
            return self
        } else if self == .leftPanel {
            return .rightPanel
        } else if self == .rightPanel {
            return .leftPanel
        }
        fatalError("Unsupported panel")
    }

    private func reorderedPages(_ appMode: OAApplicationMode,
                                screenLayoutMode: ScreenLayoutMode,
                                screenElementsMode: ScreenElementsMode? = nil) -> [[String]]? {
        let pref: OACommonListOfStringList
        if let screenElementsMode {
            pref = orderPreference(screenLayoutMode: screenLayoutMode,
                                   screenElementsMode: screenElementsMode,
                                   appMode: appMode)
        } else {
            pref = orderPreference(screenLayoutMode: screenLayoutMode, appMode: appMode)
        }
        let pages: [[String]]? = pref.get(appMode)
        guard let pages, !pages.isEmpty, isPanelVertical else {
            return pages
        }
        return WidgetsPanel.getPagedWidgetIdsWithPages(pages)
    }

    private func pagedOrder(_ widgetId: String,
                            appMode: OAApplicationMode,
                            screenLayoutMode: ScreenLayoutMode,
                            screenElementsMode: ScreenElementsMode? = nil) -> (Int, Int) {
        guard let pages = reorderedPages(appMode,
                                         screenLayoutMode: screenLayoutMode,
                                         screenElementsMode: screenElementsMode),
              !pages.isEmpty else {
            return (0, WidgetsPanel.DEFAULT_ORDER)
        }

        for (index, object) in pages.enumerated() {
            let order = object.firstIndex(of: widgetId)
            if let order {
                return (index, order)
            }
        }

        return (0, WidgetsPanel.DEFAULT_ORDER)
    }

    func updateWidgetsOrder(pagedOrder: [[String]], appMode: OAApplicationMode, screenLayoutMode: ScreenLayoutMode) {
        let preference = orderPreference(screenLayoutMode: screenLayoutMode, appMode: appMode)
        preference.set(pagedOrder, mode: appMode)
    }

    func updateWidgetsOrder(pagedOrder: [[String]],
                            appMode: OAApplicationMode,
                            screenLayoutMode: ScreenLayoutMode,
                            screenElementsMode: ScreenElementsMode) {
        let preference = orderPreference(screenLayoutMode: screenLayoutMode,
                                         screenElementsMode: screenElementsMode,
                                         appMode: appMode)
        preference.set(pagedOrder, mode: appMode)
    }

    func contains(widgetId: String, appMode: OAApplicationMode, screenLayoutMode: ScreenLayoutMode) -> Bool {
        widgetOrder(widgetId, appMode: appMode, screenLayoutMode: screenLayoutMode) != WidgetsPanel.DEFAULT_ORDER
    }

    func contains(widgetId: String,
                  appMode: OAApplicationMode,
                  screenLayoutMode: ScreenLayoutMode,
                  screenElementsMode: ScreenElementsMode) -> Bool {
        widgetOrder(widgetId,
                    appMode: appMode,
                    screenLayoutMode: screenLayoutMode,
                    screenElementsMode: screenElementsMode) != WidgetsPanel.DEFAULT_ORDER
    }

    func orderPreference(screenLayoutMode: ScreenLayoutMode, appMode: OAApplicationMode) -> OACommonListOfStringList {
        let screenElementsMode = ScreenElementsMode(usesSeparateLayouts: OAAppSettings.sharedManager().useSeparateLayouts.get(appMode))
        return orderPreference(screenLayoutMode: screenLayoutMode,
                               screenElementsMode: screenElementsMode,
                               appMode: appMode)
    }

    func orderPreference(screenLayoutMode: ScreenLayoutMode,
                         screenElementsMode: ScreenElementsMode,
                         appMode: OAApplicationMode) -> OACommonListOfStringList {
        OAAppSettings.sharedManager().widgetPanelOrder(self,
                                                       screenLayoutMode: screenLayoutMode.rawValue,
                                                       screenElementsMode: screenElementsMode.rawValue)
    }

    static func getPagedWidgetIdsWithPages(_ pages: [[String]]) -> [[String]] {
       var newPages: [[String]] = []
       var currentPage: [String] = []

       for page in pages {
           for id in page {
               if WidgetType.isComplexWidget(id) {
                   if !currentPage.isEmpty {
                       newPages.append(currentPage)
                       currentPage = []
                   }
                   newPages.append([id])
               } else {
                   currentPage.append(id)
               }
           }
           if !currentPage.isEmpty {
               newPages.append(currentPage)
           }
       }
       return newPages
    }

    func copy(with zone: NSZone? = nil) -> Any {
        self
    }
}
