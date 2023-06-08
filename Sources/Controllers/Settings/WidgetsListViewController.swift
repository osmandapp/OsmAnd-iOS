//
//  OAWidgetsListViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 24.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

protocol WidgetStateDelegate: AnyObject {
    func onWidgetStateChanged()
}

@objc(OAWidgetsListViewController)
@objcMembers
class WidgetsListViewController: OABaseSegmentedControlViewController {
    
    private static let enabledWidgetsFilter = Int(KWidgetModeAvailable | kWidgetModeEnabled)
    
    weak var delegate: WidgetStateDelegate?
    private var enabledWidgets: Set<MapWidgetInfo> = Set()
    
    let panels = WidgetsPanel.values
    
    var widgetPanel: WidgetsPanel! {
        didSet {
            navigationItem.title = getTitle()
            
            updateUI(true)
        }
    }
    
    private var selectedAppMode: OAApplicationMode {
        get {
            OAAppSettings.sharedManager().applicationMode.get()
        }
    }
    
    lazy private var widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry!
    lazy private var widgetsSettingsHelper = WidgetsSettingsHelper(appMode: selectedAppMode)
    
    init(widgetPanel: WidgetsPanel!) {
        self.widgetPanel = widgetPanel
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func createSegmentControl() -> UISegmentedControl? {
        let segmentedControl = UISegmentedControl(items: [
            UIImage(named: "ic_custom20_screen_side_left")!,
            UIImage(named: "ic_custom20_screen_side_right")!,
            UIImage(named: "ic_custom20_screen_side_top")!,
            UIImage(named: "ic_custom20_screen_side_bottom")!])
        segmentedControl.selectedSegmentIndex = panels.firstIndex(of: widgetPanel) ?? 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        return segmentedControl
    }
    
    func segmentedControlValueChanged(_ control: UISegmentedControl) {
        widgetPanel = panels[control.selectedSegmentIndex]
    }
    
    override func generateData() {
        tableData.clearAllData()
        enabledWidgets.removeAll()
        let allWidgets = tableData.createNewSection()
        updateEnabledWidgets(allWidgets)
        updateAvailableWidgets(allWidgets)
    }
    
    func updateAvailableWidgets(_ section: OATableSectionData) {
        
        var filter = Int(KWidgetModeAvailable | kWidgetModeDefault)
        
        let availableWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: filter, panels: widgetPanel.getMergedPanels())!
        let hasAvailableWidgets = availableWidgets.count > 0
        
        if hasAvailableWidgets {
            let disabledDefaultWidgets = listDefaultWidgets(availableWidgets)
            let externalWidgets = listExternalWidgets(availableWidgets)
            
            inflateAvailableDefaultWidgets(/*excludeGroupsDuplicated(disabledDefaultWidgets)*/disabledDefaultWidgets, section: section, hasExternalWidgets: !externalWidgets.isEmpty)
            inflateAvailableExternalWidgets(externalWidgets, section: section)
        }
    }
    
    private func excludeGroupsDuplicated(_ widgets: [WidgetType]) -> [WidgetType] {
        var visitedGroups: [WidgetGroup] = []
        var individualWidgets: [WidgetType] = []
        var result: [WidgetType] = []
        
        for widget in widgets {
            if let group = widget.getGroup(), !visitedGroups.contains(group) {
                visitedGroups.append(group)
                result.append(widget)
            } else if widget.getGroup() == nil {
                individualWidgets.append(widget)
            }
        }
        
        result.append(contentsOf: individualWidgets)
        return result
    }

    private func inflateAvailableDefaultWidgets(_ widgets: [MapWidgetInfo], section: OATableSectionData, hasExternalWidgets: Bool) {
        for i in 0..<widgets.count {
            let widgetInfo = widgets[i]
            let nightMode = OAAppSettings.sharedManager().nightMode
//            let widgetGroup = widgetInfo.getGroup()
            let row = section.createNewRow()
            row.setObj(widgetInfo, forKey: "widget_info")
//            if let widgetGroup {
//                row.iconName = widgetGroup.getIconName(nightMode: nightMode)
//            } else {
            row.iconName = widgetInfo.widget.widgetType?.dayIconName
//            }
            // TODO: getGroupTitle
            row.title = /*widgetGroup != nil ? widgetGroup!.title : */widgetInfo.getTitle()
            row.cellType = OASwitchTableViewCell.getIdentifier()
        }
    }

    private func inflateAvailableExternalWidgets(_ externalWidgets: [MapWidgetInfo], section: OATableSectionData) {
        
        for i in 0..<externalWidgets.count {
            let widgetInfo = externalWidgets[i]
            
            let row = section.createNewRow()
            row.setObj(widgetInfo, forKey: "widget_info")
            row.iconName = widgetInfo.getMapIconId(nightMode: OAAppSettings.sharedManager().nightMode)
            row.title = widgetInfo.getTitle()
            row.descr = widgetInfo.getMessage()
            row.cellType = OASwitchTableViewCell.getIdentifier()
        }
    }

    private func listDefaultWidgets(_ widgets: NSOrderedSet) -> [MapWidgetInfo] {
        var defaultWidgets: [Int: WidgetType] = [:]
        
        var allWidgets = [MapWidgetInfo]()
        for widgetInfo in widgets {
            if let widgetInfo = widgetInfo as? MapWidgetInfo {
                
                let widgetType = widgetInfo.getWidgetType()
                defaultWidgets[widgetType.ordinal] = widgetType
                allWidgets.append(contentsOf: widgetRegistry.getWidgetInfo(for: widgetType))
            }
        }
        allWidgets.sort { $0.widget.widgetType?.ordinal ?? 0 > $1.widget.widgetType?.ordinal ?? 0 }
        return allWidgets
    }

    private func listExternalWidgets(_ widgets: NSOrderedSet) -> [MapWidgetInfo] {
        var externalWidgets: [MapWidgetInfo] = []
        
        for widgetInfo in widgets {
            if let widgetInfo = widgetInfo as? MapWidgetInfo, widgetInfo.isExternal() {
                externalWidgets.append(widgetInfo)
            }
        }
        
        return externalWidgets
    }
    
    private func createWidgetItems(_ obj: NSOrderedSet, _ section: OATableSectionData) {
        for widget in obj {
            guard let widget = widget as? MapWidgetInfo else { continue }
            let row = section.createNewRow()
            row.setObj(widget, forKey: "widget_info")
            row.iconName = widget.getMapIconId(nightMode: OAAppSettings.sharedManager().nightMode)
            row.title = widget.getTitle()
            row.descr = widget.getMessage()
            row.cellType = OASwitchTableViewCell.getIdentifier()
        }
    }
    
    func updateEnabledWidgets(_ section: OATableSectionData) {
        let enabledWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Self.enabledWidgetsFilter, panels: [widgetPanel])!
        let noEnabledWidgets = enabledWidgets.count == 0
        if noEnabledWidgets {
            
        } else {
            // TODO: add enabled items in the correct ui
            self.enabledWidgets.formUnion(enabledWidgets.array as! [MapWidgetInfo])
            if (widgetPanel.isPagingAllowed()) {
                let pagedWidgets = widgetRegistry.getPagedWidgets(forPanel: selectedAppMode, panel: widgetPanel, filterModes: Self.enabledWidgetsFilter)!
                // TODO: Use index for header UI
//                for (i, obj) in pagedWidgets.enumerated() {
//                    createWidgetItems(obj, section)
//                }
            } else {
                let widgets = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Self.enabledWidgetsFilter, panels: [widgetPanel])
//                createWidgetItems(widgets, section)
            }
        }
    }
}

// TableView
extension WidgetsListViewController {
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        if (item.cellType == OASwitchTableViewCell.getIdentifier()) {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.getIdentifier()) as? OASwitchTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASwitchTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASwitchTableViewCell
                cell?.descriptionVisibility(false)
            }
            if let cell {
                cell.leftIconView.image = UIImage(named: item.iconName ?? "")
                cell.titleLabel.text = item.title
                cell.descriptionLabel.text = item.descr
                if let widgetInfo = item.obj(forKey: "widget_info") as? MapWidgetInfo {
                    cell.switchView.isOn = enabledWidgets.contains(widgetInfo)
                } else {
                    cell.switchView.isOn = false
                }
                cell.switchView.tag = indexPath.row
                cell.switchView.addTarget(self, action: #selector(onSwitchClick(_:)), for: .valueChanged)
            }
            outCell = cell
        }
        return outCell
    }
    
    @objc func onSwitchClick(_ sender: Any) -> Bool {
        guard let sw = sender as? UISwitch else {
            return false
        }
        
        let indexPath = IndexPath(row: sw.tag, section: 0)
        let data = tableData.item(for: indexPath)
        
        if let widgetInfo = data.obj(forKey: "widget_info") as? MapWidgetInfo {
            onWidgetsSelectedToAdd(widgetsIds: [widgetInfo.key], panel: widgetPanel, shouldAdd: sw.isOn)
        }
        delegate?.onWidgetStateChanged()
        
        return false
    }
    
    func onWidgetsSelectedToAdd(widgetsIds: [String], panel: WidgetsPanel, shouldAdd: Bool) {
        let filter = KWidgetModeAvailable | kWidgetModeEnabled
        
        for widgetId in widgetsIds {
            guard let widgetInfo = widgetRegistry.getWidgetInfo(byId: widgetId) else { continue }
            
            let widgetInfos = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Int(filter), panels: WidgetsPanel.values)
            
//            if panel.isDuplicatesAllowed() && (widgetInfo == nil || widgetInfos.contains(widgetInfo)) {
//                widgetInfo = createDuplicateWidget(widgetId, panel)
//            }
            
            if shouldAdd {
                addWidgetToEnd(widgetInfo, widgetsPanel: panel)
            }
            widgetRegistry.enableDisableWidget(for: selectedAppMode, widgetInfo: widgetInfo, enabled: NSNumber(value: shouldAdd), recreateControls: false)
        }
        
        OARootViewController.instance().mapPanel.recreateControls()
        
//        onWidgetsConfigurationChanged()
    }
    
    func addWidgetToEnd(_ targetWidget: MapWidgetInfo, widgetsPanel: WidgetsPanel) {
        var pagedOrder = [Int: [String]]()
        let enabledWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Int(kWidgetModeEnabled), panels: [widgetsPanel])!
        
        widgetRegistry.getWidgetsFor(targetWidget.widgetPanel).remove(targetWidget)
        targetWidget.widgetPanel = widgetsPanel
        
        for widget in enabledWidgets {
            guard let widget = widget as? MapWidgetInfo else { continue }
            let page = widget.pageIndex
            var orders = pagedOrder[page] ?? [String]()
            orders.append(widget.key)
            pagedOrder[page] = orders
        }
        
        if pagedOrder.isEmpty {
            targetWidget.pageIndex = 0
            targetWidget.priority = 0
            widgetRegistry.getWidgetsFor(widgetsPanel).add(targetWidget)
            
            let flatOrder: [[String]] = [[targetWidget.key]]
            widgetsPanel.setWidgetsOrder(pagedOrder: flatOrder, appMode: selectedAppMode)
        } else {
            var pages = Array(pagedOrder.keys)
            var orders = Array(pagedOrder.values)
            var lastPageOrder = orders[orders.count - 1]
            
            lastPageOrder.append(targetWidget.key)
            
            let previousLastWidgetId = lastPageOrder[lastPageOrder.count - 2]
            if let previousLastVisibleWidgetInfo = widgetRegistry.getWidgetInfo(byId: previousLastWidgetId) {
                let lastPage = previousLastVisibleWidgetInfo.pageIndex
                let lastOrder = previousLastVisibleWidgetInfo.priority + 1
                targetWidget.pageIndex = lastPage
                targetWidget.priority = lastOrder
            } else {
                let lastPage = pages[pages.count - 1]
                let lastOrder = lastPageOrder.count - 1
                targetWidget.pageIndex = lastPage
                targetWidget.priority = lastOrder
            }
            
            widgetRegistry.getWidgetsFor(widgetsPanel).add(targetWidget)
            
            widgetsPanel.setWidgetsOrder(pagedOrder: orders, appMode: selectedAppMode)
        }
    }


}

// Appearance
extension WidgetsListViewController {
    
//    func setupBottomFonts() {
//        topButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
//        bottomButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
//    }
    
    override func getTitle() -> String! {
        widgetPanel.title
    }
    // TODO: add buttons in new design
//    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
//        .horizontal
//    }
//
//    override func getTopButtonTitle() -> String {
//        return localizedString("add_widget")
//    }
//
//    override func getBottomButtonTitle() -> String {
//        return localizedString("shared_string_edit")
//    }
//
//    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
//        return .graySimple
//    }
//
//    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
//        return .graySimple
//    }
}
