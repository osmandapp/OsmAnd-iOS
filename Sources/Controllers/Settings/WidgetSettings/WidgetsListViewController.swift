//
//  OAWidgetsListViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 24.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAWidgetsListViewController)
@objcMembers
class WidgetsListViewController: OABaseSegmentedControlViewController {
    
    private static let enabledWidgetsFilter = Int(KWidgetModeAvailable | kWidgetModeEnabled)
    
    let panels = WidgetsPanel.values
    
    private var widgetPanel: WidgetsPanel! {
        didSet {
            navigationItem.title = getTitle()
            
            updateUI(true)
        }
    }
    
    private var editMode: Bool = false {
        didSet {
            tableView.isEditing = editMode
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
    
    override func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(onWidgetStateChanged), name: NSNotification.Name(kWidgetVisibilityChangedMotification), object: nil)
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
        updateEnabledWidgets()
    }
    
    private func createWidgetItems(_ obj: NSOrderedSet, _ section: OATableSectionData) {
        for widget in obj {
            guard let widget = widget as? MapWidgetInfo else { continue }
            let row = section.createNewRow()
            row.setObj(widget, forKey: "widget_info")
            row.iconName = widget.widget.widgetType?.getIconName(OAAppSettings.sharedManager().nightMode)
            row.title = widget.getTitle()
            row.descr = widget.getMessage()
            row.cellType = OASimpleTableViewCell.getIdentifier()
        }
    }
    
    func updateEnabledWidgets() {
        let enabledWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Self.enabledWidgetsFilter, panels: [widgetPanel])!
        let noEnabledWidgets = enabledWidgets.count == 0
        if noEnabledWidgets {
            // TODO: show empty state
        } else {
            if (widgetPanel.isPagingAllowed()) {
                let pagedWidgets = widgetRegistry.getPagedWidgets(forPanel: selectedAppMode, panel: widgetPanel, filterModes: Self.enabledWidgetsFilter)!
                for (i, obj) in pagedWidgets.enumerated() {
                    let section = tableData.createNewSection()
                    section.headerText = String(format:localizedString("shared_string_page_number"), i + 1)
                    createWidgetItems(obj, section)
                }
            } else {
                let section = tableData.createNewSection()
                let widgets = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Self.enabledWidgetsFilter, panels: [widgetPanel])
                if let widgets {
                    createWidgetItems(widgets, section)
                }
            }
        }
    }
}

// MARK: TableView
extension WidgetsListViewController {
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        if (item.cellType == OASimpleTableViewCell.getIdentifier()) {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASimpleTableViewCell
                cell?.descriptionVisibility(false)
                cell?.accessoryType = .disclosureIndicator
            }
            if let cell = cell {
                
                cell.titleLabel.text = item.title
                cell.leftIconView.image = UIImage(named: item.iconName ?? "")
            }
            outCell = cell
        }
        return outCell
    }
    
    @objc func onWidgetStateChanged() {
        updateUI(true)
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
            let vc = WidgetConfigurationViewController()!
            vc.selectedAppMode = selectedAppMode
            vc.widgetInfo = item.obj(forKey: "widget_info") as? MapWidgetInfo
            vc.widgetPanel = widgetPanel
            show(vc)
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // TODO: delete section reorder logic is in ReorderWidgetsAdapter, ReorderWidgetsAdapterHelper in Android
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let row = tableData.item(for: sourceIndexPath)
        tableData.removeRow(at: sourceIndexPath)
        tableData.addRow(at: destinationIndexPath, row: row)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = tableData.item(for: indexPath)
            if let widgetInfo = item.obj(forKey: "widget_info") as? MapWidgetInfo {
                tableData.removeRow(at: indexPath)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                deleteWidget(widgetInfo)
            }
        }
    }
    
    private func deleteWidget(_ widgetInfo: MapWidgetInfo) {
        widgetRegistry.enableDisableWidget(for: selectedAppMode, widgetInfo: widgetInfo, enabled: NSNumber(value: false), recreateControls: true)
    }
    
    override func tableView(_ tableView: UITableView,
                            targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                            toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.section >= self.sectionsCount() {
            let prevSection = proposedDestinationIndexPath.section - 1
            let lastRowInSection = self.rowsCount(prevSection)
            return IndexPath(row: lastRowInSection, section: prevSection)
        }
        return proposedDestinationIndexPath
    }
}

// MARK: Appearance
extension WidgetsListViewController {
    
    func setupBottomFonts() {
        topButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        bottomButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
    }
    
    override func getTitle() -> String! {
        widgetPanel.title
    }

    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        .horizontal
    }

    override func getTopButtonTitle() -> String {
        return localizedString("add_widget")
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        editMode ? localizedString("shared_string_cancel") : nil
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        if editMode {
            let button = createRightNavbarButton(localizedString("shared_string_done"), iconName: nil, action: #selector(onRightNavbarButtonPressed), menu: nil)
            return [button!]
        }
        return nil
    }
    
    override func onRightNavbarButtonPressed() {
        var arr = [MapWidgetInfo]()
        var orders = [[String]]()
        var currPage = [String]()
        for sec in 0..<tableData.sectionCount() {
            let section = tableData.sectionData(for: sec)
            for r in 0..<section.rowCount() {
                let rowData = section.getRow(r)
                if let row = rowData.obj(forKey: "widget_info") as? MapWidgetInfo {
                    currPage.append(row.key)
                    arr.append(row)
                }
            }
            orders.append(currPage)
            currPage = [String]()
        }
        
        widgetPanel.setWidgetsOrder(pagedOrder: orders, appMode: selectedAppMode)
        widgetRegistry.reorderWidgets()
        OARootViewController.instance().mapPanel.recreateControls()
        editMode = false
    }
    
    override func onLeftNavbarButtonPressed() {
        if editMode {
            editMode = false
            return
        }
        super.onLeftNavbarButtonPressed()
    }

    override func getBottomButtonTitle() -> String {
        return localizedString(editMode ? "add_page" : "shared_string_edit")
    }

    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        return .graySimple
    }

    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        return .graySimple
    }
    
    override func onTopButtonPressed() {
        let vc = WidgetGroupListViewController()
        vc.widgetPanel = widgetPanel
        show(vc)
    }
    
    override func onBottomButtonPressed() {
        if (editMode) {
            let section = tableData.createNewSection()
            section.headerText = String(format:localizedString("shared_string_page_number"), tableData.sectionCount())
            tableView.reloadData()
        } else {
            editMode = true
        }
    }
}
