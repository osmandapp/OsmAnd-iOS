//
//  ConfigureScreenViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 18.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit
import Foundation

@objc(OAConfigureScreenViewController)
@objcMembers
class ConfigureScreenViewController: OABaseNavbarViewController, AppModeSelectionDelegate {
    
    static let selectedKey = "selected"
    
    var widgetRegistry: OAMapWidgetRegistry?
    var appMode: OAApplicationMode? {
        didSet {
            setupNavbarButtons()
        }
    }
    
    
    override func generateData() {
        widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
        let settings = OAAppSettings.sharedManager()!
        appMode = settings.applicationMode.get()
        
        let widgetsSection = tableData!.createNewSection()!
        widgetsSection.headerText = localizedString("shared_string_widgets")
        widgetsSection.footerText = localizedString("widget_panels_descr")
        let panels: [WidgetsPanel] = [.leftPanel, .rightPanel, .topPanel, .bottomPanel]
        for panel in panels {
            let widgetsCount = getWidgetsCount(panel: panel)
            let row = widgetsSection.createNewRow()
            row.cellType = OAValueTableViewCell.getIdentifier()
            row.title = panel.title
            row.iconName = panel.iconName
            row.setObj(panel, forKey: "panel")
            row.iconTint = Int(widgetsCount == 0 ? color_tint_gray : appMode!.getIconColor())
            row.descr = String(widgetsCount)
            row.accessibilityLabel = panel.title
            row.accessibilityValue = String(format: localizedString("ltr_or_rtl_combine_via_colon"), localizedString("shared_string_widgets"), String(widgetsCount))
        }
        let transparencyRow = widgetsSection.createNewRow()
        transparencyRow.title = localizedString("map_widget_transparent")
        transparencyRow.key = "map_widget_transparent"
        transparencyRow.accessibilityLabel = localizedString("map_widget_transparent")
        transparencyRow.setObj(NSNumber(value: settings.transparentMapTheme.get()), forKey: Self.selectedKey)
        transparencyRow.cellType = OASwitchTableViewCell.getIdentifier()
        
        let buttonsSection = tableData!.createNewSection()!
        buttonsSection.headerText = localizedString("shared_string_buttons")
        populateCompassRow(buttonsSection.createNewRow())
        let distByTapRow = buttonsSection.createNewRow()
        distByTapRow.title = localizedString("map_widget_distance_by_tap")
        distByTapRow.iconName = "ic_action_ruler_line"
        distByTapRow.key = "map_widget_distance_by_tap"
        distByTapRow.accessibilityLabel = distByTapRow.title
        distByTapRow.accessibilityLabel = settings.showDistanceRuler.get() ? localizedString("shared_string_on") : localizedString("shared_string_off")
        distByTapRow.setObj(NSNumber(value: settings.showDistanceRuler.get()), forKey: Self.selectedKey)
        distByTapRow.cellType = OASwitchTableViewCell.getIdentifier()
        
        let quickActionsCount = OAQuickActionRegistry.sharedInstance().getQuickActionsCount()
        let quickActionsEnabled = settings.quickActionIsOn.get()
        let actionsString = quickActionsEnabled ? String(quickActionsCount) : localizedString("shared_string_off")
        let quickActionRow = buttonsSection.createNewRow()
        quickActionRow.title = localizedString("configure_screen_quick_action")
        quickActionRow.descr = quickActionsEnabled ? String(format: localizedString("ltr_or_rtl_combine_via_colon"),
                                                            localizedString("shared_string_actions"),
                                                            actionsString) : actionsString
        quickActionRow.iconTint = Int(quickActionsEnabled ? appMode!.getIconColor() : color_tint_gray)
        quickActionRow.key = "quick_action"
        quickActionRow.iconName = "ic_custom_quick_action"
        quickActionRow.cellType = OAValueTableViewCell.getIdentifier()
        quickActionRow.accessibilityLabel = quickActionRow.title
        quickActionRow.accessibilityValue = quickActionRow.descr
        
    }
    
    func populateCompassRow(_ row: OATableRowData) {
        let compassMode = EOACompassMode(rawValue: Int(OAAppSettings.sharedManager()!.compassMode.get()))!
        let descr = OACompassMode.getTitle(compassMode) ?? ""
        let title = localizedString("map_widget_compass")
        
        row.title = title
        row.descr = descr
        row.accessibilityLabel = title
        row.accessibilityValue = descr
        row.setObj(title, forKey: "")
        row.key = "compass"
        row.iconTint = Int(Int(appMode?.getIconColor() ?? color_tint_gray))
        row.iconName = OACompassMode.getIconName(compassMode)
        row.cellType = OAValueTableViewCell.getIdentifier()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func getTitle() -> String! {
        localizedString("layer_map_appearance")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        let button = createRightNavbarButton(nil, iconName: appMode?.getIconName(), action: #selector(onRightNavbarButtonPressed), menu: nil)
        button?.accessibilityLabel = localizedString("selected_profile")
        button?.accessibilityValue = appMode?.toHumanString()
        return [button!]
    }
    
    override func onRightNavbarButtonPressed() {
        let modeSelectionVc = AppModeSelectionViewController()
        modeSelectionVc.delegate = self
        let navigationController = UINavigationController()
        navigationController.setViewControllers([modeSelectionVc], animated: true)
        
        navigationController.modalPresentationStyle = .pageSheet
        let sheet = navigationController.sheetPresentationController
        if let sheet
        {
            sheet.detents = [.medium(), .large()]
            sheet.preferredCornerRadius = 20
        }
        self.navigationController?.present(navigationController, animated: true)
    }
    
    override func isNavbarSeparatorVisible() -> Bool {
        false
    }
    
    func getWidgetsCount(panel: WidgetsPanel) -> Int {
        let filter = Int(kWidgetModeEnabled | KWidgetModeAvailable)
        return widgetRegistry!.getWidgetsForPanel(appMode, filterModes: filter, panels: [panel]).count
    }
    
    // MARK: AppModeSelectionDelegate
    func onAppModeSelected(_ appMode: OAApplicationMode) {
        OAAppSettings.sharedManager()!.setApplicationModePref(appMode)
        self.appMode = appMode
    }
    
    func onNewProfilePressed() {
        let vc = OACreateProfileViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// TableView
extension ConfigureScreenViewController {
    
    fileprivate func applyAccessibility(_ cell: UITableViewCell, _ item: OATableRowData) {
        cell.accessibilityLabel = item.accessibilityLabel
        cell.accessibilityValue = item.accessibilityValue
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData!.item(for: indexPath)!
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
                cell.valueLabel.text = item.descr
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
                cell.leftIconView.tintColor = UIColor(rgb: item.iconTint)
                cell.titleLabel.text = item.title
                applyAccessibility(cell, item)
            }
            outCell = cell
        } else if item.cellType == OASwitchTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.getIdentifier()) as? OASwitchTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASwitchTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASwitchTableViewCell
                cell?.descriptionVisibility(false)
            }
            if let cell {
                cell.leftIconVisibility(!(item.iconName?.isEmpty ?? true))
                if !cell.leftIconView.isHidden {
                    cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
                }
                cell.titleLabel.text = item.title
                cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
                let selected = item.bool(forKey: Self.selectedKey)
                cell.switchView.isOn = selected
                cell.leftIconView.tintColor = UIColor(rgb: Int(selected ? color_primary_purple : color_tint_gray))

                cell.switchView.tag = indexPath.section << 10 | indexPath.row
                cell.switchView.addTarget(self, action: #selector(onSwitchClick(_:)), for: .valueChanged)
                
                applyAccessibility(cell, item)
                outCell = cell
            }
        }
        return outCell
    }
    
    @objc func onSwitchClick(_ sender: Any) -> Bool {
        guard let sw = sender as? UISwitch else {
            return false
        }
        
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        guard let data = tableData!.item(for: indexPath) else {
            return false
        }
        
        let settings = OAAppSettings.sharedManager()!
        if data.key == "map_widget_transparent" {
            settings.transparentMapTheme.set(sw.isOn)
        }
        
        if let cell = self.tableView.cellForRow(at: indexPath) as? OASwitchTableViewCell, !cell.leftIconView.isHidden {
            UIView.animate(withDuration: 0.2) {
                cell.leftIconView.tintColor = UIColor(rgb: sw.isOn ? Int(settings.applicationMode.get().getIconColor()) : Int(color_tint_gray))
            }
        }
        
        return false
    }

    override func onRowSelected(_ indexPath: IndexPath!) {
        guard let data = tableData!.item(for: indexPath) else {
            return
        }
        if data.key == "quick_action" {
            let vc = OAQuickActionListViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        } else if data.key == "compass" {
//        TODO: Needs widget refactoring
//            let vc = OAConfigureMenuViewController(configureMenuScreen: .visibility, param: data.key)!
//            vc.showFull = true
//            vc.show(self, parentViewController: nil, animated: true)
        } else {
            let panel = data.obj(forKey: "panel") as? WidgetsPanel
            if let panel {
                let vc = WidgetsListViewController(widgetPanel: panel)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

}
