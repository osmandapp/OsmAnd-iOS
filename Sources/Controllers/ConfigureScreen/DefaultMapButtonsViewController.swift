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
    private var appMode: OAApplicationMode!
    private var map3DButtonState: Map3DButtonState!
    private var compassButtonState: CompassButtonState!
    
    // MARK: Initialization
    
    override func commonInit() {
        appMode = OAAppSettings.sharedManager().applicationMode.get()
        let mapButtonsHelper = OAMapButtonsHelper.sharedInstance()
        map3DButtonState = mapButtonsHelper.getMap3DButtonState()
        compassButtonState = mapButtonsHelper.getCompassButtonState()
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
                                             image: UIImage(systemName: "gobackward")) { [weak self] _ in
            let actionSheet = UIAlertController(title: self?.title,
                                                message: localizedString("reset_all_settings_desc"),
                                                preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_reset"), style: .destructive) { _ in
                guard let self else { return }
                self.map3DButtonState.visibilityPref.resetMode(toDefault: self.appMode)
                self.compassButtonState.visibilityPref.resetMode(toDefault: self.appMode)
                self.onSettingsChanged()
            })
            actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
            if let popoverController = actionSheet.popoverPresentationController {
                popoverController.barButtonItem = self?.navigationItem.rightBarButtonItem
            }
            self?.present(actionSheet, animated: true)
        }
        let copyAction: UIAction = UIAction(title: localizedString("copy_from_other_profile"),
                                            image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
            guard let self else { return }
            
            let bottomSheet: OACopyProfileBottomSheetViewControler = OACopyProfileBottomSheetViewControler(mode: self.appMode)
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
        
        let iconTintColor = UIColor(rgb: Int(appMode.getIconColor()))
        let buttonsSection = tableData.createNewSection()
        
        let compassRow = buttonsSection.createNewRow()
        compassRow.key = "compass"
        compassRow.cellType = OAValueTableViewCell.reuseIdentifier
        compassRow.title = compassButtonState.getName()
        compassRow.descr = getDescription(compassButtonState)
        compassRow.accessibilityLabel = compassRow.title
        compassRow.accessibilityValue = compassRow.descr
        compassRow.iconTintColor = compassButtonState.isEnabled() ? iconTintColor : UIColor.iconColorDefault
        compassRow.icon = compassButtonState.getIcon()
        
        let map3dModeRow = buttonsSection.createNewRow()
        map3dModeRow.key = "map3DMode"
        map3dModeRow.cellType = OAValueTableViewCell.reuseIdentifier
        map3dModeRow.title = map3DButtonState.getName()
        map3dModeRow.descr = getDescription(map3DButtonState)
        map3dModeRow.accessibilityLabel = map3dModeRow.title
        map3dModeRow.accessibilityValue = map3dModeRow.descr
        map3dModeRow.iconTintColor = map3DButtonState.isEnabled() ? iconTintColor : UIColor.iconColorDefault
        map3dModeRow.icon = map3DButtonState.getIcon()
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
        let data = tableData.item(for: indexPath)
        if data.key == "compass" {
            let vc = CompassVisibilityViewController()
            vc.delegate = self
            showMediumSheetViewController(vc, isLargeAvailable: false)
        } else if data.key == "map3DMode" {
            let vc = Map3dModeButtonVisibilityViewController()
            vc.delegate = self
            showMediumSheetViewController(vc, isLargeAvailable: false)
        }
    }
    
    // MARK: Additions
    
    private func onSettingsChanged() {
        reloadDataWith(animated: true, completion: nil)
        delegate?.onButtonsChanged()
    }
    
    private func getDescription(_ buttonState: MapButtonState) -> String {
        switch buttonState {
        case let map3DButtonState as Map3DButtonState:
            return map3DButtonState.getVisibility().title
        case let compassButtonState as CompassButtonState:
            return compassButtonState.getVisibility().title
        default:
            return ""
        }
    }
}

// MARK: WidgetStateDelegate
extension DefaultMapButtonsViewController: WidgetStateDelegate {
    func onWidgetStateChanged() {
        onSettingsChanged()
    }
}

// MARK: OACopyProfileBottomSheetDelegate
extension DefaultMapButtonsViewController: OACopyProfileBottomSheetDelegate {
    func onCopyProfileCompleted() {
    }
    func onCopyProfile(_ fromAppMode: OAApplicationMode) {
        map3DButtonState.visibilityPref.set(map3DButtonState.getVisibility(fromAppMode).rawValue, mode: appMode)
        compassButtonState.visibilityPref.set(compassButtonState.getVisibility(fromAppMode).rawValue, mode: appMode)
        onSettingsChanged()
    }
}
