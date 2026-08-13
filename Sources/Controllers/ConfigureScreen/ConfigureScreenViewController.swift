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
class ConfigureScreenViewController: OABaseNavbarSubviewViewController, AppModeSelectionDelegate, WidgetStateDelegate, MapButtonsDelegate {

    private let selectedKey = "selected"
    private let screenElementsKey = "screen_elements"
    private let separatorHorizontalInset: CGFloat = 16
    private let screenElementsDetentHeightRatio: CGFloat = 0.8

    private var settings: OAAppSettings!
    private var appMode: OAApplicationMode!
    private var mapButtonsHelper: OAMapButtonsHelper!
    private var screenLayoutMode: ScreenLayoutMode = .defaultMode
    private var screenElementsMode: ScreenElementsMode = .defaultMode

    private var isSharedLandscapeLayout: Bool {
        screenLayoutMode == .landscape && screenElementsMode == .shared
    }

    // MARK: Initialization

    override func commonInit() {
        settings = OAAppSettings.sharedManager()
        appMode = settings.applicationMode.get()
        mapButtonsHelper = OAMapButtonsHelper.sharedInstance()
        updateScreenElementsMode()
    }

    override func registerObservers() {
        addNotification(NSNotification.Name(kWidgetVisibilityChangedMotification), selector: #selector(onWidgetStateChanged))
    }

    // MARK: Base UI

    override func getTitle() -> String {
        localizedString("layer_map_appearance")
    }

    override func createSubview() -> UIView {
        let segmentedControl = UISegmentedControl(items: ScreenLayoutMode.allCases.map { $0.title })
        segmentedControl.selectedSegmentIndex = Int(screenLayoutMode.rawValue)
        segmentedControl.addTarget(self, action: #selector(onLayoutModeChanged(_:)), for: .valueChanged)
        return segmentedControl
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        let screenElementsAction = UIAction(title: localizedString("screen_elements"),
                                            image: .icCustomMapScreenLayoutPortrait) { [weak self] _ in
            self?.showScreenElements()
        }
        let copyAction = UIAction(title: localizedString("copy_from_other_profile"),
                                  image: .icCustomCopy) { [weak self] _ in
            guard let self, let bottomSheet = OACopyProfileBottomSheetViewControler(mode: self.appMode) else { return }
            bottomSheet.delegate = self
            bottomSheet.present(in: self)
        }
        let resetAction = UIAction(title: localizedString("reset_to_default"),
                                   image: .icCustomReset) { [weak self] _ in
            self?.showResetToDefaultAlert()
        }
        let screenElementsSection = UIMenu(title: "", options: .displayInline, children: [screenElementsAction])
        let profileActionsSection = UIMenu(title: "", options: .displayInline, children: [copyAction, resetAction])
        let menu = UIMenu(title: "", children: [screenElementsSection, profileActionsSection])
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
        menuButton.tintColor = .iconColorBlack
        menuButton.accessibilityLabel = localizedString("shared_string_options")

        var buttons = [menuButton]
        if let profileButton = createRightNavbarButton(nil, iconName: appMode.getIconName(), action: #selector(onRightNavbarButtonPressed), menu: nil) {
            profileButton.customView?.tintColor = appMode.getProfileColor()
            profileButton.accessibilityLabel = localizedString("selected_profile")
            profileButton.accessibilityValue = appMode.toHumanString()
            if #available(iOS 26.0, *) {
                profileButton.style = .prominent
                profileButton.tintColor = .clear
            }
            buttons.append(profileButton)
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

    override func shouldShowSubviewSeparator() -> Bool {
        false
    }

    // MARK: Table data

    override func generateData() {
        tableData.clearAllData()

        if isSharedLandscapeLayout {
            let screenElementsSection = tableData.createNewSection()
            let screenElementsRow = screenElementsSection.createNewRow()
            screenElementsRow.key = screenElementsKey
            screenElementsRow.cellType = HorizontalEmptyCell.reuseIdentifier
        }
        
        let widgetsSection = tableData.createNewSection()
        widgetsSection.headerText = localizedString("shared_string_widgets")

        let visibleWidgetPanels = !isSharedLandscapeLayout ? WidgetsPanel.values : []
        if !visibleWidgetPanels.isEmpty {
            widgetsSection.footerText = localizedString("widget_panels_descr")
            for panel in visibleWidgetPanels {
                let widgetsCount = getWidgetsCount(panel: panel)
                let row = widgetsSection.createNewRow()
                row.cellType = OAValueTableViewCell.reuseIdentifier
                row.title = panel.title
                row.iconName = panel.getIconName(screenLayoutMode)
                row.setObj(panel, forKey: "panel")
                row.iconTintColor = widgetsCount == 0 ? .iconColorDefault : appMode!.getProfileColor()
                row.descr = String(widgetsCount)
                row.accessibilityLabel = panel.title
                row.accessibilityValue = String(format: localizedString("ltr_or_rtl_combine_via_colon"), localizedString("shared_string_widgets"), String(widgetsCount))
            }
        }
        let panelsLayoutPreference = settings.getPanelsLayoutMode(screenLayoutMode.rawValue, screenElementsMode: screenElementsMode.rawValue)
        let panelsLayoutMode = PanelsLayoutMode(rawValue: panelsLayoutPreference.get(appMode)) ?? .defaultMode
        let panelsLayoutRow = widgetsSection.createNewRow()
        panelsLayoutRow.key = "panels_layout"
        panelsLayoutRow.title = localizedString("panels_layout")
        panelsLayoutRow.descr = panelsLayoutMode.title
        panelsLayoutRow.iconName = panelsLayoutMode.iconName(for: screenLayoutMode)
        panelsLayoutRow.iconTintColor = appMode.getProfileColor()
        panelsLayoutRow.cellType = OAValueTableViewCell.reuseIdentifier
        panelsLayoutRow.accessibilityLabel = panelsLayoutRow.title
        panelsLayoutRow.accessibilityValue = panelsLayoutRow.descr
        if !isSharedLandscapeLayout {
            panelsLayoutRow.setObj(NSNumber(true), forKey: "isCustomLeftSeparatorInset")
        }

        let transparencyRow = widgetsSection.createNewRow()
        transparencyRow.title = localizedString("map_widget_transparent")
        transparencyRow.key = "map_widget_transparent"
        transparencyRow.accessibilityLabel = localizedString("map_widget_transparent")
        transparencyRow.setObj(NSNumber(value: settings.transparentMapTheme.get()), forKey: selectedKey)
        transparencyRow.cellType = OASwitchTableViewCell.reuseIdentifier

        if isSharedLandscapeLayout {
            return
        }
        
        let buttonsSection = tableData.createNewSection()
        buttonsSection.headerText = localizedString("shared_string_buttons")

        let customButtons = mapButtonsHelper.getButtonsStates()
        let enabledCustomButtons = mapButtonsHelper.getEnabledButtonsStates()
        let customButtonsRow = buttonsSection.createNewRow()
        customButtonsRow.key = "customButtons"
        customButtonsRow.title = localizedString("custom_buttons")
        customButtonsRow.descr = String(format: localizedString("ltr_or_rtl_combine_via_slash"), "\(enabledCustomButtons.count)", "\(customButtons.count)")
        customButtonsRow.iconTintColor = !enabledCustomButtons.isEmpty ? appMode.getProfileColor() : .iconColorDefault
        customButtonsRow.iconName = "ic_custom_quick_action"
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
        defaultButtonsRow.iconName = "ic_custom_button_default"
        defaultButtonsRow.cellType = OAValueTableViewCell.reuseIdentifier
        defaultButtonsRow.accessibilityLabel = defaultButtonsRow.title
        defaultButtonsRow.accessibilityValue = defaultButtonsRow.descr
        
        let otherSection = tableData.createNewSection()
        otherSection.headerText = localizedString("other_location")
        let positionMapRow = otherSection.createNewRow()
        positionMapRow.title = localizedString("position_on_map")
        positionMapRow.iconName = getLocationPositionIcon()
        positionMapRow.iconTintColor = appMode.getProfileColor()
        positionMapRow.key = "position_on_map"
        positionMapRow.descr = getLocationPositionValue()
        positionMapRow.cellType = OAValueTableViewCell.reuseIdentifier
        positionMapRow.accessibilityLabel = positionMapRow.title
        positionMapRow.accessibilityValue = positionMapRow.descr
        
        let distByTapRow = otherSection.createNewRow()
        distByTapRow.title = localizedString("map_widget_distance_by_tap")
        distByTapRow.iconName = "ic_action_ruler_line"
        distByTapRow.iconTintColor = appMode.getProfileColor()
        distByTapRow.key = "map_widget_distance_by_tap"
        distByTapRow.setObj(NSNumber(value: settings.showDistanceRuler.get()), forKey: selectedKey)
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
            speedomenterRow.iconName = "widget_speed"
            speedomenterRow.iconTintColor = nil
        } else {
            speedomenterRow.iconName = "ic_custom_speedometer_outlined"
            speedomenterRow.iconTintColor = .iconColorDefault
        }
    }

    func getWidgetsCount(panel: WidgetsPanel) -> Int {
        // todo
        let filter = Int(kWidgetModeEnabled | KWidgetModeAvailable | kWidgetModeMatchingPanels)
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
        return widgetRegistry.getWidgetsForPanel(appMode, filterModes: filter, panels: [panel]).count
    }
    
    // MARK: AppModeSelectionDelegate
    func onAppModeSelected(_ appMode: OAApplicationMode) {
        settings.setApplicationModePref(appMode)
        self.appMode = appMode
        updateScreenElementsMode()
        updateUIAnimated(nil)
    }
    
    func onNewProfilePressed() {
        let vc = OACreateProfileViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func getLocationPositionIcon() -> String {
        guard let placement = EOAPositionPlacement(rawValue: Int(OAAppSettings.sharedManager().positionPlacementOnMap.get(appMode))) else { return "" }
        switch placement {
        case .auto:
            return "ic_custom_display_position_automatic"
        case .center:
            return "ic_custom_display_position_center"
        case .bottom:
            return "ic_custom_display_position_bottom"
        @unknown default:
            debugPrint("Unknown EOAPositionPlacement value: \(placement). Using default icon.")
            return ""
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
    
    private func showResetToDefaultAlert() {
        let actionSheet = UIAlertController(title: title,
                                            message: localizedString("reset_all_settings_desc"),
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_reset"), style: .destructive) { [weak self] _ in
            guard let self else { return }
            let helper = WidgetsSettingsHelper(appMode: appMode)
            helper.setLayoutMode(screenLayoutMode)
            helper.resetConfigureScreenSettings()
            applyConfigureScreenSettings()
        })
        actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        actionSheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.first
        present(actionSheet, animated: true)
    }

    private func applyConfigureScreenSettings() {
        updateScreenElementsMode()
        OARootViewController.instance().mapPanel.recreateAllControls()
        reloadDataWith(animated: true, completion: nil)
    }

    private func updateScreenElementsMode() {
        screenElementsMode = ScreenElementsMode(usesSeparateLayouts: settings.useSeparateLayouts.get(appMode))
    }

    private func showScreenElements() {
        let screenElementsViewController = ScreenElementsViewController(appMode: appMode)
        screenElementsViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: screenElementsViewController)
        navigationController.modalPresentationStyle = .pageSheet
        present(navigationController, animated: true)
    }

    @objc private func onLayoutModeChanged(_ segmentedControl: UISegmentedControl) {
        guard let mode = ScreenLayoutMode(rawValue: Int32(segmentedControl.selectedSegmentIndex)),
              mode != screenLayoutMode else { return }
        screenLayoutMode = mode
        reloadDataWith(animated: true, completion: nil)
    }
}

// TableView
extension ConfigureScreenViewController {
    override func registerCells() {
        addCell(OAValueTableViewCell.reuseIdentifier)
        addCell(OASwitchTableViewCell.reuseIdentifier)
        tableView.register(HorizontalEmptyCell.self, forCellReuseIdentifier: HorizontalEmptyCell.reuseIdentifier)
    }
    
    fileprivate func applyAccessibility(_ cell: UITableViewCell, _ item: OATableRowData) {
        cell.accessibilityLabel = item.accessibilityLabel
        cell.accessibilityValue = item.accessibilityValue
    }

    fileprivate func applySeparatorInsets(_ cell: OASimpleTableViewCell, isCustomLeftSeparatorInset: Bool) {
        cell.setCustomLeftSeparatorInset(true)
        if !isCustomLeftSeparatorInset {
            cell.updateSeparatorInset()
        }
        cell.separatorInset = UIEdgeInsets(top: 0,
                                           left: isCustomLeftSeparatorInset
                                               ? separatorHorizontalInset
                                               : cell.separatorInset.left,
                                           bottom: 0,
                                           right: separatorHorizontalInset)
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == HorizontalEmptyCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HorizontalEmptyCell.reuseIdentifier,
                                                           for: indexPath) as? HorizontalEmptyCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("screen_elements"),
                           description: localizedString("screen_elements_descr"),
                           icon: .icCustomMapScreenLayoutPortraitColored,
                           iconTint: nil,
                           isOriginalIcon: true,
                           actionTitle: localizedString("switch_to_independent"),
                           action: { [weak self] in
                               self?.showScreenElements()
                           })
            return cell
        } else if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.descriptionVisibility(false)
            cell.valueLabel.text = item.descr
            cell.titleLabel.text = item.title
            if let iconTintColor = item.iconTintColor {
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
                if item.key == "map_widget_distance_by_tap" {
                    let selected = item.bool(forKey: selectedKey)
                    cell.leftIconView.tintColor = selected ? iconTintColor : .iconColorDefault
                } else {
                    cell.leftIconView.tintColor = iconTintColor
                }
            } else if let iconName = item.iconName {
                cell.leftIconView.image = UIImage(named: iconName)
            }
            applyAccessibility(cell, item)
            applySeparatorInsets(cell, isCustomLeftSeparatorInset: item.bool(forKey: "isCustomLeftSeparatorInset"))
            return cell
        } else if item.cellType == OASwitchTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier, for: indexPath) as! OASwitchTableViewCell
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(!(item.iconName?.isEmpty ?? true))
            if !cell.leftIconView.isHidden {
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
            }

            let selected = item.bool(forKey: selectedKey)
            cell.leftIconView.tintColor = selected ? item.iconTintColor : .iconColorDefault
            cell.titleLabel.text = item.title
            cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
            cell.switchView.isOn = selected
            cell.switchView.tag = indexPath.section << 10 | indexPath.row
            cell.switchView.addTarget(self, action: #selector(onSwitchClick(_:)), for: .valueChanged)
            applyAccessibility(cell, item)
            applySeparatorInsets(cell, isCustomLeftSeparatorInset: item.bool(forKey: "isCustomLeftSeparatorInset"))
            return cell
        }
        return nil
    }
    
    @objc func onSwitchClick(_ sender: Any) -> Bool {
        guard let sw = sender as? UISwitch else {
            return false
        }
        
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        let data = tableData.item(for: indexPath)
        
        if data.key == "map_widget_transparent" {
            settings.transparentMapTheme.set(sw.isOn)
            OARootViewController.instance().mapPanel.hudViewController?.mapInfoController.updateLayout()
        }
        
        if let cell = self.tableView.cellForRow(at: indexPath) as? OASwitchTableViewCell, !cell.leftIconView.isHidden {
            UIView.animate(withDuration: 0.2) {
                cell.leftIconView.tintColor = sw.isOn ? self.settings.applicationMode.get().getProfileColor() : .iconColorDefault
            }
        }
        
        return false
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
        } else if data.key == "panels_layout" {
            let vc = PanelsLayoutViewController(screenLayoutMode: screenLayoutMode,
                                                screenElementsMode: screenElementsMode,
                                                appMode: appMode)
            vc.delegate = self
            let navigationController = UINavigationController(rootViewController: vc)
            navigationController.modalPresentationStyle = .pageSheet
            present(navigationController, animated: true)
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
        updateScreenElementsMode()
        reloadDataWith(animated: true, completion: nil)
    }
    
    func closeSettingsScreenWithRouteInfo() {
    }
    
    func openNavigationSettings() {
    }
}

// MARK: OACopyProfileBottomSheetDelegate
extension ConfigureScreenViewController: OACopyProfileBottomSheetDelegate {
    func onCopyProfileCompleted() {
    }

    func onCopyProfile(_ fromAppMode: OAApplicationMode) {
        guard let appMode else { return }
        let helper = WidgetsSettingsHelper(appMode: appMode)
        helper.setLayoutMode(screenLayoutMode)
        helper.copyConfigureScreenSettings(fromAppMode: fromAppMode,
                                           widgetParams: ["selectedAppMode": appMode])
        applyConfigureScreenSettings()
    }
}
