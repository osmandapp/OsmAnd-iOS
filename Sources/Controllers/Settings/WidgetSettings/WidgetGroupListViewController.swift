//
//  WidgetGroupListViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 27.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetGroupListViewController)
@objcMembers
class WidgetGroupListViewController: OABaseNavbarViewController, UISearchBarDelegate {
    
    private var searchController: UISearchController!
    private var isFiltered = false
    
    private var filteredSection: OATableSectionData!
    
    private static let enabledWidgetsFilter = Int(KWidgetModeAvailable | kWidgetModeEnabled | kWidgetModeMatchingPanels)
    lazy private var widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
    
    var widgetPanel: WidgetsPanel!
    
    override func generateData() {
        filteredSection = OATableSectionData()
        tableData.clearAllData()
        let section = tableData.createNewSection()
        updateAvailableWidgets(section)
    }
    
    override func registerNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    func updateAvailableWidgets(_ section: OATableSectionData) {
        
        let filter = Int(KWidgetModeAvailable | kWidgetModeDefault)
        
        let availableWidgets = widgetRegistry.getWidgetsForPanel(OAAppSettings.sharedManager().applicationMode.get(), filterModes: filter, panels: [widgetPanel])!
        let hasAvailableWidgets = availableWidgets.count > 0
        
        if hasAvailableWidgets {
            let disabledDefaultWidgets = listDefaultWidgets(availableWidgets)
            let externalWidgets = listExternalWidgets(availableWidgets)
            
            inflateAvailableDefaultWidgets(excludeGroupsDuplicated(disabledDefaultWidgets), section: section, hasExternalWidgets: !externalWidgets.isEmpty)
            inflateAvailableExternalWidgets(externalWidgets, section: section)
        }
    }
    
    private func excludeGroupsDuplicated(_ widgets: [WidgetType]) -> [WidgetType] {
        var visitedGroups: [WidgetGroup] = []
        var individualWidgets: [WidgetType] = []
        var result: [WidgetType] = []
        
        for widget in widgets {
            let group = widget.getGroup()
            if group != nil, !visitedGroups.contains(group!) {
                visitedGroups.append(group!)
                result.append(widget)
            } else if group == nil {
                individualWidgets.append(widget)
            }
        }
        
        result.append(contentsOf: individualWidgets)
        return result
    }

    private func inflateAvailableDefaultWidgets(_ widgets: [WidgetType], section: OATableSectionData, hasExternalWidgets: Bool) {
        let sortedWidgets = widgets.sorted( by: { w0, w1 in
            let group0 = w0.getGroup()
            let group1 = w1.getGroup()
            let title0 = group0 != nil ? group0!.title : w0.title
            let title1 = group1 != nil ? group1!.title : w1.title
            return title0 < title1
        })
        let nightMode = OAAppSettings.sharedManager().nightMode
        for i in 0..<sortedWidgets.count {
            let widgetType = sortedWidgets[i]
            let widgetGroup = widgetType.getGroup()
            let row = section.createNewRow()
            row.setObj(widgetType, forKey: "widget_type")
            if let widgetGroup {
                row.iconName = widgetGroup.iconName
                row.setObj(widgetGroup, forKey: "widget_group")
            } else {
                row.iconName = widgetType.iconName
            }
            row.title = widgetGroup != nil ? widgetGroup!.title : widgetType.title
            row.descr = String(widgetGroup?.getWidgets().count ?? 1)
            row.cellType = OAValueTableViewCell.getIdentifier()
        }
    }

    private func inflateAvailableExternalWidgets(_ externalWidgets: [MapWidgetInfo], section: OATableSectionData) {
        let sortedWidgets = externalWidgets.sorted { $0.key < $1.key }
        for i in 0..<sortedWidgets.count {
            let widgetInfo = sortedWidgets[i]
            
            let row = section.createNewRow()
            row.setObj(widgetInfo, forKey: "widget_info")
            row.iconName = widgetInfo.getMapIconId(nightMode: OAAppSettings.sharedManager().nightMode)
            row.title = widgetInfo.getTitle()
            row.descr = "1"
            row.cellType = OAValueTableViewCell.getIdentifier()
        }
    }
    
    private func listDefaultWidgets(_ widgets: NSOrderedSet) -> [WidgetType] {
        var defaultWidgets: [Int: WidgetType] = [:]
        for widgetInfo in widgets {
            let widgetType: WidgetType? = (widgetInfo as? MapWidgetInfo)?.getWidgetType()
            if widgetType != nil {
                defaultWidgets[widgetType!.ordinal] = widgetType
            }
        }
        return Array(defaultWidgets.values)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        self.navigationItem.searchController = searchController
        setupSearchControllerWithFilter(false)
    }
    
    private func setupSearchControllerWithFilter(_ isFiltered: Bool) {
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: localizedString("shared_string_search"), attributes: [NSAttributedString.Key.foregroundColor: UIColor(rgb: color_text_footer)])
        searchController.searchBar.searchTextField.backgroundColor = UIColor(white: 1.0, alpha: 0.3)
        if isFiltered {
            searchController.searchBar.searchTextField.leftView?.tintColor = UIColor(white: 0, alpha: 0.8)
        } else {
            searchController.searchBar.searchTextField.leftView?.tintColor = UIColor(white: 0, alpha: 0.3)
            searchController.searchBar.searchTextField.tintColor = UIColor.gray
        }
    }
    
    // MARK: - UISearchBarDelegate

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isFiltered = false
        setupSearchControllerWithFilter(false)
        tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isFiltered = !searchText.isEmpty
        setupSearchControllerWithFilter(isFiltered)
        filteredSection.removeAllRows()
        guard isFiltered else {
            tableView.reloadData()
            return
        }
        
        let section = tableData.sectionData(for: 0)
        for i in 0..<section.rowCount() {
            let row = section.getRow(i)
            if let widgetGroup = row.obj(forKey: "widget_group") as? WidgetGroup {
                if containsCaseInsensitive(text: widgetGroup.title, substring: searchText) {
                    filteredSection.addRow(row)
                }
                
                widgetGroup.getWidgets().forEach {
                    if containsCaseInsensitive(text: $0.title, substring: searchText) {
                        filteredSection.addRow(createSearchRowData(for: $0))
                    }
                }
            } else if let widgetType = row.obj(forKey: "widget_type") as? WidgetType,
                      containsCaseInsensitive(text: widgetType.title, substring: searchText) {
                filteredSection.addRow(row)
            }
        }
        
        tableView.reloadData()
    }
    
    private func containsCaseInsensitive(text: String, substring: String) -> Bool {
        text.range(of: substring, options: .caseInsensitive) != nil
    }
    
    private func createSearchRowData(for widget: WidgetType) -> OATableRowData {
        let newRow = OATableRowData()
        newRow.cellType = OAValueTableViewCell.getIdentifier()
        newRow.setObj(widget, forKey: "widget_type")
        newRow.title = widget.title
        newRow.iconName = widget.iconName
        return newRow
    }
    
    // MARK: - Keyboard Notifications

    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardBounds = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? CGFloat,
              let animationCurveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }
        
        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveValue)
        
        UIView.animate(withDuration: duration, delay: 0, options: animationCurve, animations: {
            var insets = self.tableView.contentInset
            insets.bottom = keyboardBounds.size.height
            self.tableView.contentInset = insets
            self.tableView.scrollIndicatorInsets = insets
        }, completion: nil)
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? CGFloat,
              let animationCurveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }
        
        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveValue)
        
        UIView.animate(withDuration: duration, delay: 0, options: animationCurve, animations: {
            var insets = self.tableView.contentInset
            insets.bottom = 0.0
            self.tableView.contentInset = insets
            self.tableView.scrollIndicatorInsets = insets
        }, completion: nil)
    }
}

// MARK: Appearance
extension WidgetGroupListViewController {
    
    override func getTitle() -> String! {
        localizedString("add_widget")
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        localizedString("shared_string_cancel")
    }
    
}

// MARK: TableView
extension WidgetGroupListViewController {
    
    private func getItem(_ indexPath: IndexPath!) -> OATableRowData {
        if isFiltered {
            return filteredSection.getRow(UInt(indexPath.row))
        }
        return tableData.item(for: indexPath)
    }
    
    override func rowsCount(_ section: Int) -> Int {
        if isFiltered {
            return Int(filteredSection.rowCount())
        }
        return super.rowsCount(section)
    }
    
    override func sectionsCount() -> Int {
        if isFiltered {
            return 1
        }
        return super.sectionsCount()
    }
    
    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        0.001
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = getItem(indexPath)
        var outCell: UITableViewCell? = nil
        if item.cellType == OAValueTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.getIdentifier()) as? OAValueTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OAValueTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OAValueTableViewCell
                cell?.accessoryType = .disclosureIndicator
                cell?.descriptionVisibility(false)
            }
            if let cell {
                cell.leftIconView.image = UIImage(named: item.iconName ?? "")
                cell.titleLabel.text = item.title
                cell.valueLabel.text = item.descr
                
                cell.accessoryView = nil
                let widgetGroup = item.obj(forKey: "widget_group") as? WidgetGroup
                if let widgetType = item.obj(forKey: "widget_type") as? WidgetType, !widgetType.isPurchased(), widgetGroup == nil {
                    cell.accessoryView = UIImageView(image: UIImage.icPaymentLabelPro)
                    cell.valueLabel.text = ""
                }
            }
            outCell = cell
        }
        return outCell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = getItem(indexPath)
        if let widgetGroup = item.obj(forKey: "widget_group") as? WidgetGroup {
            let vc = WidgetGroupItemsViewController()
            vc.widgetPanel = widgetPanel
            vc.widgetGroup = widgetGroup
            show(vc)
        } else if let widgetType = item.obj(forKey: "widget_type") as? WidgetType {
            guard let vc = WidgetConfigurationViewController(),
                  let widgetInfo = widgetRegistry.getWidgetInfo(for: widgetType) else {
                return
            }
            if let enabledWidgets = widgetRegistry.getWidgetsForPanel(OAAppSettings.sharedManager().applicationMode.get(), filterModes: Self.enabledWidgetsFilter, panels: WidgetsPanel.values).array as? [MapWidgetInfo] {
                let similarAlreadyExist = enabledWidgets.contains { $0.key == widgetInfo.key }
                let possibleSimilarWidgetArray = [WidgetType.averageSpeed.id]
                if similarAlreadyExist, possibleSimilarWidgetArray.contains(widgetInfo.key) {
                    vc.similarAlreadyExist = similarAlreadyExist
                    vc.widgetKey = widgetInfo.key
                }
                if widgetType.isPurchased() {
                    vc.selectedAppMode = OAAppSettings.sharedManager().applicationMode.get()
                    vc.widgetInfo = widgetInfo
                    vc.widgetPanel = widgetPanel
                    vc.createNew = true
                    show(vc)
                } else if widgetType == .altitudeMapCenter {
                    if let navigationController {
                        OAChoosePlanHelper.showChoosePlanScreen(with: OAIAPHelper().srtm, navController: navigationController)
                    }
                }
            }
        }
    }
}
