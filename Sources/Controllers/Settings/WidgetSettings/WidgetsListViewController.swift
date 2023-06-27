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
            row.iconName = widget.getMapIconId(nightMode: OAAppSettings.sharedManager().nightMode)
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
        generateData()
        tableView.reloadData()
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
}

// Appearance
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

    override func getBottomButtonTitle() -> String {
        return localizedString("shared_string_edit")
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
        // TODO: enter edit mode
    }
}
