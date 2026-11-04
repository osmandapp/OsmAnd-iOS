//
//  WidgetsPanel.swift
//  OsmAnd Maps
//
//  Created by Paul on 28.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class WidgetsPanel: NSObject, NSCopying {
    
    static let leftPanel = WidgetsPanel(.icCustomScreenSideLeft,
                                       landscapeIcon: .icCustomScreenSideLeftLandscape,
                                       title: localizedString("map_widget_left"))
    static let rightPanel = WidgetsPanel(.icCustomScreenSideRight,
                                        landscapeIcon: .icCustomScreenSideRightLandscape,
                                        title: localizedString("map_widget_right"))
    static let topPanel = WidgetsPanel(.icCustomScreenSideTop,
                                      landscapeIcon: .icCustomScreenSideTopLandscape,
                                      title: localizedString("top_widgets_panel"))
    static let bottomPanel = WidgetsPanel(.icCustomScreenSideBottom,
                                         landscapeIcon: .icCustomScreenSideBottomLandscape,
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
    
    var isPanelVertical: Bool {
        self == .topPanel || self == .bottomPanel
    }
    
    private let portraitIcon: UIImage
    private let landscapeIcon: UIImage

    internal required init(_ portraitIcon: UIImage, landscapeIcon: UIImage, title: String) {
        self.title = title
        self.portraitIcon = portraitIcon
        self.landscapeIcon = landscapeIcon
    }

    func icon(for screenLayoutMode: ScreenLayoutMode) -> UIImage {
        screenLayoutMode.isPortrait ? portraitIcon : landscapeIcon
    }

    func originalOrder() -> [String] {
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
        let order = originalOrder().firstIndex(of: widgetId)
        return order ?? WidgetsPanel.DEFAULT_ORDER
    }
    
    func widgetPage(_ widgetId: String, appMode: OAApplicationMode, screenLayoutMode: NSNumber?) -> Int {
        pagedOrder(widgetId, appMode: appMode, screenLayoutMode: screenLayoutMode).0
    }
    
    func widgetOrder(_ widgetId: String, appMode: OAApplicationMode, screenLayoutMode: NSNumber?) -> Int {
        pagedOrder(widgetId, appMode: appMode, screenLayoutMode: screenLayoutMode).1
    }

    private func reorderedPages(_ appMode: OAApplicationMode,
                                screenLayoutMode: NSNumber?) -> [[String]]? {
        let pref = orderPreference(screenLayoutMode: screenLayoutMode)
        let pages: [[String]]? = pref.get(appMode)
        guard let pages, !pages.isEmpty, isPanelVertical else {
            return pages
        }
        return WidgetsPanel.getPagedWidgetIdsWithPages(pages)
    }

    private func pagedOrder(_ widgetId: String,
                            appMode: OAApplicationMode,
                            screenLayoutMode: NSNumber?) -> (Int, Int) {
        guard let pages = reorderedPages(appMode,
                                         screenLayoutMode: screenLayoutMode),
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

    func setWidgetsOrder(pagedOrder: [[String]], appMode: OAApplicationMode, screenLayoutMode: NSNumber?) {
        let preference = orderPreference(screenLayoutMode: screenLayoutMode)
        preference.set(pagedOrder, mode: appMode)
    }

    func contains(widgetId: String, appMode: OAApplicationMode, screenLayoutMode: NSNumber?) -> Bool {
        widgetOrder(widgetId, appMode: appMode, screenLayoutMode: screenLayoutMode) != WidgetsPanel.DEFAULT_ORDER
    }

    func orderPreference(screenLayoutMode: NSNumber?) -> OACommonListOfStringList {
        OAAppSettings.sharedManager().widgetPanelOrder(self,
                                                       screenLayoutMode: screenLayoutMode)
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
