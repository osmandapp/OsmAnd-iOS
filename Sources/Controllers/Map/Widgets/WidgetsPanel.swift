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
class WidgetsPanel: NSObject {
    
    static let leftPanel = WidgetsPanel(title: localizedString("map_widget_left"))
    static let rightPanel = WidgetsPanel(title: localizedString("map_widget_right"))
    static let topPanel = WidgetsPanel(title: localizedString("top_widgets_panel"))
    static let bottomPanel = WidgetsPanel(title: localizedString("bottom_widgets_panel"))
    
    static let DEFAULT_ORDER = 1000
    
    private static func getOrderIds(_ panel: WidgetsPanel) -> [String] {
        return WidgetType.values.reduce(into: [String]()) { result, type in
            let id = type.id
            let defaultPanel = type.defaultPanel
            if (defaultPanel == panel) {
                result.append(id)
            }
        }
    }

    private static var ORIGINAL_LEFT_ORDER = getOrderIds(.leftPanel)
    private static var ORIGINAL_RIGHT_ORDER = getOrderIds(.rightPanel)
    private static var ORIGINAL_TOP_ORDER = getOrderIds(.topPanel)
    private static var ORIGINAL_BOTTOM_ORDER = getOrderIds(.bottomPanel)
    
    let title: String
    
    required init(title: String) {
        self.title = title
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
        if (self == .leftPanel) {
            return WidgetsPanel.ORIGINAL_LEFT_ORDER
        } else if (self == .rightPanel) {
            return WidgetsPanel.ORIGINAL_RIGHT_ORDER
        } else if (self == .topPanel) {
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
        getPagedOrder(widgetId).0
    }

    func getWidgetOrder(_ widgetId: String) -> Int {
        return getPagedOrder(widgetId).1
    }
    
    private func appMode() -> OAApplicationMode {
        OAAppSettings.sharedManager().applicationMode.get()
    }

    private func getPagedOrder(_ widgetId: String) -> (Int, Int) {
        let orderPreference = getOrderPreference()
        let pages = orderPreference.get(appMode())
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

    func setWidgetsOrder(pagedOrder: [[String]]) {
        let orderPreference = getOrderPreference()
        orderPreference.set(pagedOrder, mode: appMode())
    }


    func contains(widgetId: String) -> Bool {
        return getWidgetOrder(widgetId) != WidgetsPanel.DEFAULT_ORDER
    }

    func isPagingAllowed() -> Bool {
        return self == .leftPanel || self == .rightPanel
    }

    func isDuplicatesAllowed() -> Bool {
        return self == .leftPanel || self == .rightPanel
    }

    func getOrderPreference() -> OACommonListOfStringList {
        let settings = OAAppSettings.sharedManager()!
        if (self == .leftPanel) {
            return settings.leftWidgetPanelOrder
        } else if (self == .rightPanel) {
            return settings.rightWidgetPanelOrder
        } else if (self == .topPanel) {
            return settings.topWidgetPanelOrder
        } else if (self == .bottomPanel) {
            return settings.bottomWidgetPanelOrder
        }
        fatalError("Unsupported panel")
    }

    func getMergedPanels() -> [WidgetsPanel] {
        if (self == .leftPanel || self == .rightPanel) {
            return [.leftPanel, .rightPanel]
        } else if (self == .topPanel) {
            return [.topPanel]
        } else if (self == .bottomPanel) {
            return [.bottomPanel]
        }
        fatalError("Unsupported widgets panel")
    }
}
