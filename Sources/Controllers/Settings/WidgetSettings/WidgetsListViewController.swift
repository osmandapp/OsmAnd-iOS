//
//  OAWidgetsListViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 24.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit
import SafariServices

@objc(OAWidgetsListViewController)
@objcMembers
class WidgetsListViewController: BaseSegmentedControlViewController {

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
            updateAppearance()
        }
    }

    private var selectedAppMode: OAApplicationMode {
        get {
            OAAppSettings.sharedManager().applicationMode.get()
        }
    }

    lazy private var widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry!
    lazy private var widgetsSettingsHelper = WidgetsSettingsHelper(appMode: selectedAppMode)

    //MARK: - Initialization

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

    //MARK: - Base setup UI

    override func createSegmentControl() -> UISegmentedControl? {
        if editMode {
            return nil
        }
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

    // MARK: Selectors

    override func onLeftNavbarButtonPressed() {
        if editMode {
            editMode = false
            return
        }
        super.onLeftNavbarButtonPressed()
    }

    override func onRightNavbarButtonPressed() {
        if editMode {
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

    @objc func onWidgetStateChanged() {
        updateUI(true)
    }

    @objc func onButtonClicked(sender: UIButton) {
        let indexPath: IndexPath = IndexPath.init(row: sender.tag & 0x3FF, section:sender.tag >> 10)
        let item: OATableRowData = tableData.item(for: indexPath)
        if (item.key == "noWidgets") {
            onTopButtonPressed()
        }
    }

}

// MARK: Table data
extension WidgetsListViewController {

    override func generateData() {
        tableData.clearAllData()
        updateEnabledWidgets()
    }

    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
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
        else if item.cellType == OALargeImageTitleDescrTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OALargeImageTitleDescrTableViewCell.getIdentifier()) as? OALargeImageTitleDescrTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OALargeImageTitleDescrTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OALargeImageTitleDescrTableViewCell
                cell?.selectionStyle = .none
            }
            if let cell = cell {
                cell.titleLabel?.text = item.title
                cell.descriptionLabel?.text = item.descr
                cell.cellImageView?.image = UIImage.templateImageNamed(item.iconName)
                cell.cellImageView?.tintColor = colorFromRGB(item.iconTint)
                cell.button?.setTitle(item.obj(forKey: "buttonTitle") as? String, for: .normal)
                cell.button?.removeTarget(nil, action: nil, for: .allEvents)
                cell.button?.tag = indexPath.section << 10 | indexPath.row
                cell.button?.addTarget(self, action: #selector(onButtonClicked(sender:)), for: .touchUpInside)
            }
            outCell = cell

            let update: Bool = outCell?.needsUpdateConstraints() ?? false
            if (update) {
                outCell?.setNeedsUpdateConstraints()
            }
        }

        return outCell
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

    func updateEnabledWidgets() {
        let enabledWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Self.enabledWidgetsFilter, panels: [widgetPanel])!
        let noEnabledWidgets = enabledWidgets.count == 0
        if noEnabledWidgets && !editMode {
            let section = tableData.createNewSection()
            let row = section.createNewRow()
            row.cellType = OALargeImageTitleDescrTableViewCell.getIdentifier()
            row.key = "noWidgets"
            row.title = localizedString("no_widgets_here_yet")
            row.descr = localizedString("no_widgets_descr")
            row.iconName = "ic_custom_screen_side_bottom"
            row.iconTint = Int(color_tint_gray)
            row.setObj(localizedString("add_widget"), forKey: "buttonTitle")
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

    private func deleteWidget(_ widgetInfo: MapWidgetInfo) {
        widgetRegistry.enableDisableWidget(for: selectedAppMode, widgetInfo: widgetInfo, enabled: NSNumber(value: false), recreateControls: true)
    }

}

extension WidgetsListViewController {

    //MARK: - Base setup UI

    func setupBottomFonts() {
        topButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        bottomButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
    }

    //MARK: - Base UI

    override func getTitle() -> String! {
        widgetPanel.title
    }

    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        .horizontal
    }

    override func isNavbarSeparatorVisible() -> Bool {
        editMode
    }

    override func getLeftNavbarButtonTitle() -> String! {
        editMode ? localizedString("shared_string_cancel") : nil
    }

    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        var menuElements: [UIMenuElement]?
        if !editMode {
            let resetAction: UIAction  = UIAction(title: localizedString("reset_to_default")) { UIAction in
                let alert: UIAlertController = UIAlertController.init(title: localizedString("bottom_widgets_panel"),
                                                                      message: localizedString("reset_all_settings_desc"),
                                                                      preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: localizedString("shared_string_reset"), style: .destructive) { UIAlertAction in
                    self.widgetsSettingsHelper.setAppMode(self.selectedAppMode)
                    self.widgetsSettingsHelper.resetConfigureScreenSettings()
                    OARootViewController.instance().mapPanel.recreateControls()
                    self.updateUI(true)
                })
                alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
                self.present(alert, animated: true)
            }
            let copyAction: UIAction  = UIAction(title: localizedString("copy_from_other_profile")) { UIAction in
                let bottomSheet: OACopyProfileBottomSheetViewControler = OACopyProfileBottomSheetViewControler.init(mode: self.selectedAppMode)
                bottomSheet.delegate = self;
                bottomSheet.present(in: self)
            }
            let helpAction: UIAction  = UIAction(title: localizedString("shared_string_help")) { UIAction in
                self.openSafariWithURL("https://docs.osmand.net/docs/user/widgets/configure-screen")
            }
            menuElements = [resetAction, copyAction, helpAction]
        }
        let menu: UIMenu? = editMode ? nil : UIMenu(children: menuElements ?? [])
        let button = createRightNavbarButton(editMode ? localizedString("shared_string_done") : nil,
                                             iconName: editMode ? nil : "ic_navbar_overflow_menu_stroke",
                                             action: #selector(onRightNavbarButtonPressed),
                                             menu: menu)
        if !editMode {
            button?.accessibilityLabel = localizedString("shared_string_options")
        }
        return [button!]
    }

    override func getTopButtonTitle() -> String {
        let enabledWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode,
                                                               filterModes: Self.enabledWidgetsFilter,
                                                               panels: [widgetPanel])!
        return enabledWidgets.count > 0 ? localizedString("add_widget") : ""
    }

    override func getBottomButtonTitle() -> String {
        let enabledWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode,
                                                               filterModes: Self.enabledWidgetsFilter,
                                                               panels: [widgetPanel])!
        if (enabledWidgets.count > 0) {
            return editMode && (widgetPanel == WidgetsPanel.topPanel || widgetPanel == WidgetsPanel.bottomPanel) ? "" : localizedString(editMode ? "add_page" : "shared_string_edit")
        }
        else {
            return ""
        }
    }

    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        return .graySimple
    }

    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        return .graySimple
    }

}

// MARK: - SFSafariViewControllerDelegate

extension WidgetsListViewController: SFSafariViewControllerDelegate {

    @nonobjc func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true)
    }

    func openSafariWithURL(_ url: String)
    {
        let safariViewController:SFSafariViewController = SFSafariViewController(url: URL(string: url)!)
        safariViewController.delegate = self
        self.present(safariViewController, animated:true)
    }

}
// MARK: - OACopyProfileBottomSheetDelegate

extension WidgetsListViewController: OACopyProfileBottomSheetDelegate {

    func onCopyProfileCompleted() {
    }

    func onCopyProfile(_ fromAppMode: OAApplicationMode!) {
        widgetsSettingsHelper.setAppMode(self.selectedAppMode)
        widgetsSettingsHelper.copyConfigureScreenSettings(fromAppMode: fromAppMode)
        OARootViewController.instance().mapPanel.recreateControls()
        self.updateUI(true)
    }

}
