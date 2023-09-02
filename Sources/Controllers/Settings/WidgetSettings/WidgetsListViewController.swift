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

    static let kWidgetAddedNotification = "onWidgetAdded"

    private let kPageKey = "page_"
    private let kNoWidgetsKey = "noWidgets"
    private let kWidgetsInfoKey = "widget_info"
    private static let enabledWidgetsFilter = Int(KWidgetModeAvailable | kWidgetModeEnabled)
    

    let panels = WidgetsPanel.values

    private var widgetsToAdd: [MapWidgetInfo] = []

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

    override func registerNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onWidgetStateChanged),
                                               name: NSNotification.Name(kWidgetVisibilityChangedMotification),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onWidgetAdded(notification:)),
                                               name: NSNotification.Name(Self.kWidgetAddedNotification),
                                               object: nil)
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

    @objc private func segmentedControlValueChanged(_ control: UISegmentedControl) {
        widgetPanel = panels[control.selectedSegmentIndex]
    }

    // MARK: Selectors

    override func onLeftNavbarButtonPressed() {
        if editMode {
            widgetsToAdd.removeAll()
            editMode = false
            return
        }
        super.onLeftNavbarButtonPressed()
    }

    override func onRightNavbarButtonPressed() {
        if editMode {
            widgetsToAdd.removeAll()
            reorderWidgets()
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
            let row = section.createNewRow()
            row.key = kPageKey + String(tableData.sectionCount())
            row.title = String(format:localizedString("shared_string_page_number"), tableData.sectionCount())
            row.cellType = OASimpleTableViewCell.getIdentifier()
            tableView.reloadData()
        } else {
            editMode = true
        }
    }

    @objc private func onWidgetAdded(notification: NSNotification) {
        let widget = (notification.object as? MapWidgetInfo) ?? nil
        if widget != nil {
            if editMode {
                widgetsToAdd.append(widget!)
                updateUI(true)
            } else {
                widgetsToAdd.append(widget!)
                reorderWidgets()
            }
        }
    }

    @objc private func onWidgetStateChanged() {
        if !editMode {
            updateUI(true)
        }
    }

    @objc func onButtonClicked(sender: UIButton) {
        let indexPath: IndexPath = IndexPath.init(row: sender.tag & 0x3FF, section:sender.tag >> 10)
        let item: OATableRowData = tableData.item(for: indexPath)
        if (item.key == kNoWidgetsKey) {
            onTopButtonPressed()
        }
    }

    // MARK: Additions

    private func reorderWidgets() {
        var orders = [[String]]()
        var currPage = [String]()
        for sec in 0..<tableData.sectionCount() {
            let section = tableData.sectionData(for: sec)
            for r in 0..<section.rowCount() {
                let rowData = section.getRow(r)
                if let row = rowData.obj(forKey: kWidgetsInfoKey) as? MapWidgetInfo {
                    currPage.append(row.key)
                }
            }
            orders.append(currPage)
            currPage = [String]()
        }
        if !widgetsToAdd.isEmpty, widgetsToAdd.count == 1 {
            orders[orders.count - 1].append(widgetsToAdd.first!.key)
            widgetsToAdd.removeAll()
        }
        WidgetUtils.setEnabledWidgets(orderedWidgets: orders,
                                      panel: widgetPanel,
                                      selectedAppMode: selectedAppMode)
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
            }
            if let cell = cell {
                cell.titleLabel.text = item.title
                cell.leftIconView.image = UIImage(named: item.iconName ?? "")
                let isPageCell = item.key?.starts(with: kPageKey) ?? false
                cell.leftIconVisibility(!isPageCell)
                cell.accessoryType = isPageCell ? .none : .disclosureIndicator
                cell.selectionStyle = !tableView.isEditing && isPageCell ? .none : .default
                cell.titleLabel.textColor = isPageCell ? colorFromRGB(Int(color_extra_text_gray)) : .black
            }
            return cell
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
                cell.titleLabel?.accessibilityLabel = item.title
                cell.descriptionLabel?.text = item.descr
                cell.descriptionLabel?.accessibilityLabel = item.descr
                cell.cellImageView?.image = UIImage.templateImageNamed(item.iconName)
                cell.cellImageView?.tintColor = colorFromRGB(item.iconTint)
                cell.button?.setTitle(item.obj(forKey: "buttonTitle") as? String, for: .normal)
                cell.button?.accessibilityLabel = item.obj(forKey: "buttonTitle") as? String
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
            vc.widgetInfo = item.obj(forKey: kWidgetsInfoKey) as? MapWidgetInfo
            vc.widgetPanel = widgetPanel
            show(vc)
        }
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let item = tableData.item(for: indexPath)
        let isFirstPageCell = item.key == kPageKey + "1"
        let isNoWidgetsCell = item.key == kNoWidgetsKey
        return !isNoWidgetsCell && !isFirstPageCell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let item = tableData.item(for: indexPath)
        let isFirstPageCell = item.key == kPageKey + "1"
        let isNoWidgetsCell = item.key == kNoWidgetsKey
        return !isNoWidgetsCell && !isFirstPageCell
    }

    // TODO: delete section reorder logic is in ReorderWidgetsAdapter, ReorderWidgetsAdapterHelper in Android
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = tableData.item(for: sourceIndexPath)
        let isPageCell = item.key?.starts(with: kPageKey) ?? false
        if (isPageCell) {
            if sourceIndexPath.section == destinationIndexPath.section {
                if destinationIndexPath.row > sourceIndexPath.row {
                    let destinationSection = destinationIndexPath.section - 1
                    for _ in 1..<destinationIndexPath.row + 1 {
                        let destinationWidgetsCount = tableData.rowCount(UInt(destinationSection))
                        let movableIndexPath = IndexPath(row: 1, section: sourceIndexPath.section)
                        let movedIndexPath = IndexPath(row: Int(destinationWidgetsCount), section: destinationSection)
                        let movableItem = tableData.item(for: movableIndexPath)
                        tableData.removeRow(at: movableIndexPath)
                        tableData.addRow(at: movedIndexPath, row: movableItem)
                    }
                }
            } else if sourceIndexPath.section < destinationIndexPath.section {
                let sourceWidgetsCount = Int(tableData.rowCount(UInt(sourceIndexPath.section)))
                var destinationWidgetsCount = Int(tableData.rowCount(UInt(sourceIndexPath.section - 1)))
                for _ in sourceIndexPath.row..<sourceWidgetsCount - 1 {
                    let movableIndexPath = IndexPath(row: 1, section: sourceIndexPath.section)
                    let movedIndexPath = IndexPath(row: destinationWidgetsCount, section: sourceIndexPath.section - 1)
                    destinationWidgetsCount += 1
                    let movableItem = tableData.item(for: movableIndexPath)
                    tableData.removeRow(at: movableIndexPath)
                    tableData.addRow(at: movedIndexPath, row: movableItem)
                }
            } else {
                var counter: Int = 1
                let destinationWidgetsCount = Int(tableData.rowCount(UInt(destinationIndexPath.section)))
                for _ in destinationIndexPath.row..<destinationWidgetsCount {
                    let movedIndexPath = IndexPath(row: counter, section: sourceIndexPath.section)
                    counter += 1
                    let movableItem = tableData.item(for: destinationIndexPath)
                    tableData.removeRow(at: destinationIndexPath)
                    tableData.addRow(at: movedIndexPath, row: movableItem)
                }
            }
        } else {
            tableData.removeRow(at: sourceIndexPath)
            let movedIndexPath = destinationIndexPath.row == 0 ? IndexPath(row: 1, section: destinationIndexPath.section) : destinationIndexPath
            tableData.addRow(at: movedIndexPath, row: item)
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = tableData.item(for: indexPath)
            let isPageCell = item.key?.starts(with: kPageKey) ?? false
            if isPageCell {
                tableData.removeRow(at: indexPath)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                let widgetsCount = Int(tableData.rowCount(UInt(indexPath.section)))
                for _ in 0..<widgetsCount {
                    let prevSectionWidgetsCount = Int(tableData.rowCount(UInt(indexPath.section - 1)))
                    let movableIndexPath = IndexPath(row: 0, section: indexPath.section)
                    let movableItem = tableData.item(for: movableIndexPath)
                    let movedIndexPath = IndexPath(row: prevSectionWidgetsCount, section: indexPath.section - 1)
                    tableData.removeRow(at: movableIndexPath)
                    tableData.addRow(at: movedIndexPath, row: movableItem)
                    tableView.moveRow(at: movableIndexPath, to: movedIndexPath)
                }
                tableData.removeSection(UInt(indexPath.section))
                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
                if !editMode {
                    reorderWidgets()
                }
            }
            else if let widgetInfo = item.obj(forKey: kWidgetsInfoKey) as? MapWidgetInfo {
                tableData.removeRow(at: indexPath)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                if !editMode {
                    reorderWidgets()
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView,
                            targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                            toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let item = tableData.item(for: sourceIndexPath)
        let isPageCell = item.key?.starts(with: kPageKey) ?? false
        if isPageCell, proposedDestinationIndexPath.section > sourceIndexPath.section || (proposedDestinationIndexPath.row == 0 && proposedDestinationIndexPath.section < sourceIndexPath.section) {
            return IndexPath(row: 0, section: proposedDestinationIndexPath.section)
        } else if !isPageCell, proposedDestinationIndexPath.row == 0 {
            return IndexPath(row: 1, section: proposedDestinationIndexPath.section)
        }
        return proposedDestinationIndexPath
    }

    private func updateEnabledWidgets() {
        let enabledWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Self.enabledWidgetsFilter, panels: [widgetPanel])!
        let noEnabledWidgets = enabledWidgets.count == 0
        if noEnabledWidgets && !editMode {
            var iconName = "ic_custom_screen_side_left_48"
            if widgetPanel == .topPanel {
                iconName = "ic_custom_screen_side_top_48"
            } else if widgetPanel == .rightPanel {
                iconName = "ic_custom_screen_side_right_48"
            } else if widgetPanel == .bottomPanel {
                iconName = "ic_custom_screen_side_bottom_48"
            }
            let section = tableData.createNewSection()
            let row = section.createNewRow()
            row.cellType = OALargeImageTitleDescrTableViewCell.getIdentifier()
            row.key = kNoWidgetsKey
            row.title = localizedString("no_widgets_here_yet")
            row.descr = localizedString("no_widgets_descr")
            row.iconName = iconName
            row.iconTint = Int(color_tint_gray)
            row.setObj(localizedString("add_widget"), forKey: "buttonTitle")
        } else {
            var lastSection: OATableSectionData?
            if (widgetPanel.isPagingAllowed()) {
                let pagedWidgets = widgetRegistry.getPagedWidgets(forPanel: selectedAppMode, panel: widgetPanel, filterModes: Self.enabledWidgetsFilter)!
                for (i, obj) in pagedWidgets.enumerated() {
                    let section = tableData.createNewSection()
                    createWidgetItems(obj, section, i + 1)
                    if i == pagedWidgets.count - 1 {
                        lastSection = section
                    }
                }
            } else {
                let section = tableData.createNewSection()
                let widgets = widgetRegistry.getWidgetsForPanel(selectedAppMode, filterModes: Self.enabledWidgetsFilter, panels: [widgetPanel])
                if let widgets {
                    createWidgetItems(widgets, section)
                }
                lastSection = section
            }
            if !widgetsToAdd.isEmpty {
                if lastSection == nil {
                    lastSection = tableData.createNewSection()
                    createWidgetItems(NSOrderedSet(array: widgetsToAdd), lastSection!)
                } else {
                    for widget in widgetsToAdd {
                        createWidgetItem(widget, lastSection!)
                    }
                }
            }
        }
    }

    private func createWidgetItems(_ obj: NSOrderedSet, _ section: OATableSectionData, _ page: Int = 1) {
        let row = section.createNewRow()
        row.key = kPageKey + String(page)
        row.title = String(format:localizedString("shared_string_page_number"), page)
        row.cellType = OASimpleTableViewCell.getIdentifier()

        let sortedWidgets = (obj.array as! [MapWidgetInfo]).sorted { $0.priority < $1.priority }
        for widget in sortedWidgets {
            createWidgetItem(widget, section)
        }
    }

    private func createWidgetItem(_ widget: MapWidgetInfo, _ section: OATableSectionData) {
        let row = section.createNewRow()
        row.setObj(widget, forKey: kWidgetsInfoKey)
        row.iconName = widget.widget.widgetType?.getIconName(OAAppSettings.sharedManager().nightMode)
        row.title = widget.getTitle()
        row.descr = widget.getMessage()
        row.cellType = OASimpleTableViewCell.getIdentifier()
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
            let resetAction: UIAction  = UIAction(title: localizedString("reset_to_default"),
                                                  image: UIImage.init(systemName: "gobackward")) { UIAction in
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
            let copyAction: UIAction  = UIAction(title: localizedString("copy_from_other_profile"),
                                                 image: UIImage.init(systemName: "doc.on.doc")) { UIAction in
                let bottomSheet: OACopyProfileBottomSheetViewControler = OACopyProfileBottomSheetViewControler.init(mode: self.selectedAppMode)
                bottomSheet.delegate = self;
                bottomSheet.present(in: self)
            }
            let helpAction: UIAction  = UIAction(title: localizedString("shared_string_help"),
                                                 image: UIImage.init(systemName: "questionmark.circle")) { UIAction in
                self.openSafariWithURL("https://docs.osmand.net/docs/user/widgets/configure-screen")
            }
            let helpMenuAction: UIMenu = UIMenu(options: .displayInline, children: [helpAction])
            menuElements = [resetAction, copyAction, helpMenuAction]
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
        return editMode || enabledWidgets.count > 0 ? localizedString("add_widget") : ""
    }

    override func getBottomButtonTitle() -> String {
        let enabledWidgets = widgetRegistry.getWidgetsForPanel(selectedAppMode,
                                                               filterModes: Self.enabledWidgetsFilter,
                                                               panels: [widgetPanel])!
        if editMode || enabledWidgets.count > 0 {
            return editMode && (widgetPanel == WidgetsPanel.topPanel || widgetPanel == WidgetsPanel.bottomPanel) ? "" : localizedString(editMode ? "add_page" : "shared_string_edit")
        } else {
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
