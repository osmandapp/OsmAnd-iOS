//
//  ConfigureScreenViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 18.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit
import Foundation

@objc(OAWidgetStateDelegate)
protocol WidgetStateDelegate: AnyObject {
    func onWidgetStateChanged()
}

protocol MapButtonsDelegate: AnyObject {
    func onButtonsChanged()
}

@objc(OAConfigureScreenViewController)
@objcMembers
class ConfigureScreenViewController: OABaseNavbarViewController, AppModeSelectionDelegate, WidgetStateDelegate, MapButtonsDelegate {

    private static let selectedKey = "selected"
    private static let appearanceRowKey = "appearance"

    private var settings: OAAppSettings!
    private var appMode: OAApplicationMode!
    private var mapButtonsHelper: OAMapButtonsHelper!

    // MARK: Initialization

    override func commonInit() {
        settings = OAAppSettings.sharedManager()
        appMode = settings.applicationMode.get()
        mapButtonsHelper = OAMapButtonsHelper.sharedInstance()
    }

    override func registerObservers() {
        addNotification(NSNotification.Name(kWidgetVisibilityChangedMotification), selector: #selector(onWidgetStateChanged))
    }

    // MARK: Base UI

    override func getTitle() -> String {
        localizedString("layer_map_appearance")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        var buttons = [UIBarButtonItem]()
        if let button = createRightNavbarButton(nil, iconName: appMode.getIconName(), action: #selector(onRightNavbarButtonPressed), menu: nil) {
            button.customView?.tintColor = appMode.getProfileColor()
            button.accessibilityLabel = localizedString("selected_profile")
            button.accessibilityValue = appMode.toHumanString()
            buttons.append(button)
        }
        return buttons
    }
    
    override func onRightNavbarButtonPressed() {
        let modeSelectionVc = AppModeSelectionViewController()
        modeSelectionVc.delegate = self
        let navigationController = UINavigationController()
        navigationController.setViewControllers([modeSelectionVc], animated: true)
        
        navigationController.modalPresentationStyle = .pageSheet
        let sheet = navigationController.sheetPresentationController
        if let sheet {
            sheet.detents = [.medium(), .large()]
            sheet.preferredCornerRadius = 20
        }
        self.navigationController?.present(navigationController, animated: true)
    }
    
    override func isNavbarSeparatorVisible() -> Bool {
        false
    }

    // MARK: Table data

    override func generateData() {
        tableData.clearAllData()
        
        let widgetsSection = tableData.createNewSection()
        widgetsSection.headerText = localizedString("shared_string_widgets")
        widgetsSection.footerText = localizedString("widget_panels_descr")
        for panel in WidgetsPanel.values {
            let widgetsCount = getWidgetsCount(panel: panel)
            let row = widgetsSection.createNewRow()
            row.cellType = OAValueTableViewCell.reuseIdentifier
            row.title = panel.title
            row.iconName = panel.iconName
            row.setObj(panel, forKey: "panel")
            row.iconTintColor = (widgetsCount == 0) ? .iconColorDefault : appMode!.getProfileColor();
            row.descr = String(widgetsCount)
            row.accessibilityLabel = panel.title
            row.accessibilityValue = String(format: localizedString("ltr_or_rtl_combine_via_colon"), localizedString("shared_string_widgets"), String(widgetsCount))
            if panel == WidgetsPanel.values.last {
                row.setObj(NSNumber(true), forKey: "isCustomLeftSeparatorInset")
            }
        }
        let appearanceRow = widgetsSection.createNewRow()
        appearanceRow.key = Self.appearanceRowKey
        appearanceRow.title = localizedString("shared_string_appearance")
        appearanceRow.icon = UIImage.templateImageNamed("ic_custom_appearance")
        appearanceRow.iconTintColor = appMode.getProfileColor()
        appearanceRow.cellType = OAValueTableViewCell.reuseIdentifier
        appearanceRow.accessibilityLabel = appearanceRow.title
        
        let buttonsSection = tableData.createNewSection()
        buttonsSection.headerText = localizedString("shared_string_buttons")

        let customButtons = mapButtonsHelper.getButtonsStates()
        let enabledCustomButtons = mapButtonsHelper.getEnabledButtonsStates()
        let customButtonsRow = buttonsSection.createNewRow()
        customButtonsRow.key = "customButtons"
        customButtonsRow.title = localizedString("custom_buttons")
        customButtonsRow.descr = String(format: localizedString("ltr_or_rtl_combine_via_slash"), "\(enabledCustomButtons.count)", "\(customButtons.count)")
        customButtonsRow.iconTintColor = !enabledCustomButtons.isEmpty ? appMode.getProfileColor() : .iconColorDefault
        customButtonsRow.icon = .icCustomQuickAction
        customButtonsRow.cellType = OAValueTableViewCell.reuseIdentifier
        customButtonsRow.accessibilityLabel = customButtonsRow.title
        customButtonsRow.accessibilityValue = customButtonsRow.descr
        
        let defaultButtons = mapButtonsHelper.getDefaultButtonsStates()
        let defaultButtonsEnabledCount = defaultButtons.filter { $0.isEnabled() }.count
        let defaultButtonsRow = buttonsSection.createNewRow()
        defaultButtonsRow.key = "defaultButtons"
        defaultButtonsRow.title = localizedString("default_buttons")
        defaultButtonsRow.descr = String(format: localizedString("ltr_or_rtl_combine_via_slash"), "\(defaultButtonsEnabledCount)", "\(defaultButtons.count)")
        defaultButtonsRow.iconTintColor = defaultButtonsEnabledCount > 0 ? appMode.getProfileColor() : .iconColorDefault
        defaultButtonsRow.icon = .icCustomButtonDefault
        defaultButtonsRow.cellType = OAValueTableViewCell.reuseIdentifier
        defaultButtonsRow.accessibilityLabel = defaultButtonsRow.title
        defaultButtonsRow.accessibilityValue = defaultButtonsRow.descr
        
        let otherSection = tableData.createNewSection()
        otherSection.headerText = localizedString("other_location")
        let positionMapRow = otherSection.createNewRow()
        positionMapRow.title = localizedString("position_on_map")
        positionMapRow.icon = getLocationPositionIcon()
        positionMapRow.iconTintColor = appMode.getProfileColor()
        positionMapRow.key = "position_on_map"
        positionMapRow.descr = getLocationPositionValue()
        positionMapRow.cellType = OAValueTableViewCell.reuseIdentifier
        positionMapRow.accessibilityLabel = positionMapRow.title
        positionMapRow.accessibilityValue = positionMapRow.descr
        
        let distByTapRow = otherSection.createNewRow()
        distByTapRow.title = localizedString("map_widget_distance_by_tap")
        distByTapRow.icon = .icActionRulerLine
        distByTapRow.iconTintColor = appMode.getProfileColor()
        distByTapRow.key = "map_widget_distance_by_tap"
        distByTapRow.setObj(NSNumber(value: settings.showDistanceRuler.get()), forKey: Self.selectedKey)
        distByTapRow.descr = localizedString(settings.showDistanceRuler.get() ? "shared_string_on" : "shared_string_off")
        distByTapRow.cellType = OAValueTableViewCell.reuseIdentifier
        distByTapRow.accessibilityLabel = distByTapRow.title
        distByTapRow.accessibilityLabel = localizedString(settings.showDistanceRuler.get() ? "shared_string_on" : "shared_string_off")

        let speedomenterRow = otherSection.createNewRow()
        speedomenterRow.cellType = OAValueTableViewCell.reuseIdentifier
        speedomenterRow.key = "shared_string_speedometer"
        speedomenterRow.title = localizedString("shared_string_speedometer")
        speedomenterRow.descr = localizedString(settings.showSpeedometer.get() ? "shared_string_on" : "shared_string_off")
        speedomenterRow.accessibilityLabel = speedomenterRow.title
        speedomenterRow.accessibilityValue = speedomenterRow.descr
        if settings.showSpeedometer.get() {
            speedomenterRow.icon = .widgetSpeed
            speedomenterRow.iconTintColor = nil
        } else {
            speedomenterRow.icon = .icCustomSpeedometerOutlined
            speedomenterRow.iconTintColor = .iconColorDefault
        }
    }

    func getWidgetsCount(panel: WidgetsPanel) -> Int {
        let filter = Int(kWidgetModeEnabled | KWidgetModeAvailable | kWidgetModeMatchingPanels)
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
        return widgetRegistry.getWidgetsForPanel(appMode, filterModes: filter, panels: [panel]).count
    }
    
    // MARK: AppModeSelectionDelegate
    func onAppModeSelected(_ appMode: OAApplicationMode) {
        settings.setApplicationModePref(appMode)
        self.appMode = appMode
        updateUIAnimated(nil)
    }
    
    func onNewProfilePressed() {
        let vc = OACreateProfileViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func getLocationPositionIcon() -> UIImage? {
        guard let placement = EOAPositionPlacement(rawValue: Int(OAAppSettings.sharedManager().positionPlacementOnMap.get(appMode))) else { return nil }
        switch placement {
        case .auto:
            return .icCustomDisplayPositionAutomatic
        case .center:
            return .icCustomDisplayPositionCenter
        case .bottom:
            return .icCustomDisplayPositionBottom
        @unknown default:
            debugPrint("Unknown EOAPositionPlacement value: \(placement). Using default icon.")
            return nil
        }
    }
    
    private func getLocationPositionValue() -> String {
        guard let placement = EOAPositionPlacement(rawValue: Int(OAAppSettings.sharedManager().positionPlacementOnMap.get(appMode))) else { return "" }
        switch placement {
        case .auto:
            return localizedString("shared_string_automatic")
        case .center:
            return localizedString("position_on_map_center")
        case .bottom:
            return localizedString("position_on_map_bottom")
        @unknown default:
            debugPrint("Unknown EOAPositionPlacement value: \(placement). Using default value.")
            return ""
        }
    }
}

// TableView
extension ConfigureScreenViewController {
    override func registerCells() {
        addCell(OAValueTableViewCell.reuseIdentifier)
    }
    
    fileprivate func applyAccessibility(_ cell: UITableViewCell, _ item: OATableRowData) {
        cell.accessibilityLabel = item.accessibilityLabel
        cell.accessibilityValue = item.accessibilityValue
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.descriptionVisibility(false)
            let isCustomLeftSeparatorInset = item.bool(forKey: "isCustomLeftSeparatorInset")
            cell.setCustomLeftSeparatorInset(isCustomLeftSeparatorInset)
            cell.separatorInset = .zero
            cell.valueLabel.text = item.descr
            cell.titleLabel.text = item.title
            if let iconTintColor = item.iconTintColor {
                cell.leftIconView.image = item.icon ?? UIImage.templateImageNamed(item.iconName)
                if item.key == "map_widget_distance_by_tap" {
                    let selected = item.bool(forKey: Self.selectedKey)
                    cell.leftIconView.tintColor = selected ? iconTintColor : .iconColorDefault
                } else {
                    cell.leftIconView.tintColor = iconTintColor
                }
            } else {
                cell.leftIconView.image = item.icon ?? item.iconName.flatMap { UIImage(named: $0) }
            }
            applyAccessibility(cell, item)
            return cell
        }
        return nil
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let data = tableData.item(for: indexPath)
        if data.key == "defaultButtons" {
            let vc = DefaultMapButtonsViewController()
            vc.delegate = self
            show(vc)
        } else if data.key == "customButtons" {
            let vc = CustomMapButtonsViewController()
            vc.delegate = self
            show(vc)
        } else if data.key == "shared_string_speedometer" {
            let vc = SpeedometerWidgetSettingsViewController()
            vc.delegate = self
            show(vc)
        } else if data.key == "position_on_map" {
            if let vc = OAProfileGeneralSettingsParametersViewController(type: EOAProfileGeneralSettingsDisplayPosition, applicationMode: appMode) {
                vc.delegate = self
                showMediumSheetViewController(vc, isLargeAvailable: false)
            }
        } else if data.key == "map_widget_distance_by_tap" {
            let vc = DistanceByTapViewController()
            vc.delegate = self
            show(vc)
        } else if data.key == Self.appearanceRowKey {
            show(WidgetsAppearanceViewController(appMode: appMode))
        } else {
            let panel = data.obj(forKey: "panel") as? WidgetsPanel
            if let panel {
                let vc = WidgetsListViewController(widgetPanel: panel)
                show(vc)
            }
        }
    }
    
    // MARK: WidgetStateDelegate

    @objc func onWidgetStateChanged() {
        reloadDataWith(animated: true, completion: nil)
    }

    // MARK: WidgetStateDelegate
    func onButtonsChanged() {
        reloadDataWith(animated: true, completion: nil)
    }
}

extension ConfigureScreenViewController: OASettingsDataDelegate {
    func onSettingsChanged() {
        reloadDataWith(animated: true, completion: nil)
    }
    
    func closeSettingsScreenWithRouteInfo() {
    }
    
    func openNavigationSettings() {
    }
}
