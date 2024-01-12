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
    
    static let leftPanel = WidgetsPanel("ic_custom_screen_side_left", title: localizedString("map_widget_left"))
    static let rightPanel = WidgetsPanel("ic_custom_screen_side_right", title: localizedString("map_widget_right"))
    static let topPanel = WidgetsPanel("ic_custom_screen_side_top", title: localizedString("top_widgets_panel"))
    static let bottomPanel = WidgetsPanel("ic_custom_screen_side_bottom", title: localizedString("bottom_widgets_panel"))
    
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
    
    internal required init(_ iconName: String, title: String) {
        self.title = title
        self.iconName = iconName
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
    
    func getWidgetPage(_ widgetId: String) -> Int {
        getWidgetPage(widgetId, appMode: OAAppSettings.sharedManager().applicationMode.get()!)
    }

    func getWidgetPage(_ widgetId: String, appMode: OAApplicationMode) -> Int {
        getPagedOrder(widgetId, appMode: appMode).0
    }
    
    func getWidgetOrder(_ widgetId: String) -> Int {
        return getWidgetOrder(widgetId, appMode: OAAppSettings.sharedManager().applicationMode.get()!)
    }

    func getWidgetOrder(_ widgetId: String, appMode: OAApplicationMode) -> Int {
        return getPagedOrder(widgetId, appMode: appMode).1
    }

    private func getPagedOrder(_ widgetId: String, appMode: OAApplicationMode) -> (Int, Int) {
        let orderPreference = getOrderPreference()
        let pages = orderPreference.get(appMode)
        guard let pages, !pages.isEmpty else {
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

    func setWidgetsOrder(pagedOrder: [[String]], appMode: OAApplicationMode) {
        let orderPreference = getOrderPreference()
        orderPreference.set(pagedOrder, mode: appMode)
    }

    func contains(widgetId: String, appMode: OAApplicationMode = OAAppSettings.sharedManager().applicationMode.get()!) -> Bool {
        return getWidgetOrder(widgetId, appMode: appMode) != WidgetsPanel.DEFAULT_ORDER
    }

    func isPagingAllowed() -> Bool {
        self == .leftPanel || self == .rightPanel || self == .topPanel || self == .bottomPanel
    }

    func getOrderPreference() -> OACommonListOfStringList {
        let settings = OAAppSettings.sharedManager()!
        if self == .leftPanel {
            return settings.leftWidgetPanelOrder
        } else if self == .rightPanel {
            return settings.rightWidgetPanelOrder
        } else if self == .topPanel {
            return settings.topWidgetPanelOrder
        } else if self == .bottomPanel {
            return settings.bottomWidgetPanelOrder
        }
        fatalError("Unsupported panel")
    }

    func getMergedPanels() -> [WidgetsPanel] {
        if self == .leftPanel || self == .rightPanel {
            return [.leftPanel, .rightPanel]
        } else if self == .topPanel || self == .bottomPanel {
            return [.topPanel, .bottomPanel, .leftPanel, .rightPanel] // , .leftPanel, .rightPanel
        }
        fatalError("Unsupported widgets panel")
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        self
    }
}
