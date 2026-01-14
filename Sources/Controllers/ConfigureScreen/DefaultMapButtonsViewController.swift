//
//  DefaultMapButtonsViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 17.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

final class DefaultMapButtonsViewController: OABaseNavbarViewController {
    
    weak var delegate: MapButtonsDelegate?
    private var buttonStates: [MapButtonState] = []
    private var appMode: OAApplicationMode?
    
    // MARK: Initialization
    
    override func commonInit() {
        appMode = OAAppSettings.sharedManager().applicationMode.get()
        buttonStates = OAMapButtonsHelper.sharedInstance().getDefaultButtonsStates()
    }
    
    override func registerCells() {
        addCell(OAValueTableViewCell.reuseIdentifier)
    }
    
    // MARK: Base UI
    
    override func getTitle() -> String {
        localizedString("default_buttons")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        var resetAlert: UIAlertController?
        resetAlert = UIAlertController(title: title,
                                       message: localizedString("reset_all_settings_desc"),
                                       preferredStyle: .actionSheet)
        let resetAction: UIAction = UIAction(title: localizedString("reset_to_default"),
                                             image: .icCustomReset) { [weak self] _ in
            let actionSheet = UIAlertController(title: self?.title,
                                                message: localizedString("reset_all_settings_desc"),
                                                preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_reset"), style: .destructive) { _ in
                guard let self, let appMode = self.appMode else { return }
                self.buttonStates.forEach { $0.resetForMode(appMode) }
                self.onSettingsChanged()
            })
            actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
            if let popoverController = actionSheet.popoverPresentationController {
                popoverController.barButtonItem = self?.navigationItem.rightBarButtonItem
            }
            self?.present(actionSheet, animated: true)
        }
        let copyAction: UIAction = UIAction(title: localizedString("copy_from_other_profile"),
                                            image: .icCustomCopy) { [weak self] _ in
            guard let self, let appMode = self.appMode else { return }
            
            let bottomSheet: OACopyProfileBottomSheetViewControler = OACopyProfileBottomSheetViewControler(mode: appMode)
            bottomSheet.delegate = self
            bottomSheet.present(in: self)
        }
        let menuElements = [resetAction, copyAction]
        let menu = UIMenu(children: menuElements)
        let button = createRightNavbarButton(nil,
                                             iconName: "ic_navbar_overflow_menu_stroke",
                                             action: #selector(onRightNavbarButtonPressed),
                                             menu: menu)
        button?.accessibilityLabel = localizedString("shared_string_options")
        let popover = resetAlert?.popoverPresentationController
        popover?.barButtonItem = button
        var buttons = [UIBarButtonItem]()
        if let button {
            buttons.append(button)
        }
        return buttons
    }
    
    // MARK: Table data
    
    override func generateData() {
        tableData.clearAllData()
        guard let appMode else { return }
        let iconTintColor = appMode.getProfileColor()
        let buttonsSection = tableData.createNewSection()
        
        for buttonState in buttonStates {
            let row = buttonsSection.createNewRow()
            row.key = key(for: buttonState)
            row.cellType = OAValueTableViewCell.reuseIdentifier
            row.title = buttonState.getName()
            row.descr = getDescription(buttonState)
            row.accessibilityLabel = row.title
            row.accessibilityValue = row.descr
            row.iconTintColor = buttonState.isEnabled() ? iconTintColor : .iconColorDefault
            row.icon = buttonState.getIcon()
        }
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.descriptionVisibility(false)
            cell.valueLabel.text = item.descr
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            cell.titleLabel.text = item.title
            cell.accessibilityLabel = item.accessibilityLabel
            cell.accessibilityValue = item.accessibilityValue
            return cell
        }
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let vc = DefaultMapButtonViewController()
        vc.delegate = self
        vc.mapButtonState = buttonStates[indexPath.row]
        show(vc)
    }
    
    // MARK: Additions
    
    private func getDescription(_ buttonState: MapButtonState) -> String {
        switch buttonState {
        case let map3DButtonState as Map3DButtonState:
            return map3DButtonState.getVisibility().title
        case let compassButtonState as CompassButtonState:
            return compassButtonState.getVisibility().title
        default:
            return localizedString(buttonState.isEnabled() ? "shared_string_on" : "shared_string_off")
        }
    }
    
    private func key(for state: MapButtonState) -> String {
        switch state {
        case is Map3DButtonState: "map3DMode"
        case is CompassButtonState: "compass"
        case is ZoomInButtonState: "zoomIn"
        case is ZoomOutButtonState: "zoomOut"
        case is SearchButtonState: "search"
        case is DriveModeButtonState: "navigation"
        case is MyLocationButtonState: "myLocation"
        case is OptionsMenuButtonState: "menu"
        case is MapSettingsButtonState: "configureMap"
        default: ""
        }
    }
}

// MARK: OACopyProfileBottomSheetDelegate
extension DefaultMapButtonsViewController: OACopyProfileBottomSheetDelegate {
    func onCopyProfileCompleted() {
    }
    func onCopyProfile(_ fromAppMode: OAApplicationMode) {
        guard let appMode else { return }
        buttonStates.forEach { $0.copyForMode(from: fromAppMode, to: appMode) }
        onSettingsChanged()
    }
}

// MARK: OASettingsDataDelegate
extension DefaultMapButtonsViewController: OASettingsDataDelegate {
    func onSettingsChanged() {
        reloadDataWith(animated: true, completion: nil)
        delegate?.onButtonsChanged()
    }
    
    func closeSettingsScreenWithRouteInfo() {
    }
    
    func openNavigationSettings() {
    }
}
