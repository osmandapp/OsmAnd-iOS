//
//  DefaultMapButtonsViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 17.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

class DefaultMapButtonsViewController: OABaseNavbarViewController, OACopyProfileBottomSheetDelegate, WidgetStateDelegate {

    weak var delegate: MapButtonsDelegate?
    private var settings: OAAppSettings!
    private var appMode: OAApplicationMode!

    // MARK: Initialization

    override func commonInit() {
        settings = OAAppSettings.sharedManager()
        appMode = settings.applicationMode.get()
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
                self.settings.compassMode.resetMode(toDefault: self.appMode)
                self.settings.map3dMode.resetMode(toDefault: self.appMode)
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
        let defaultCompassMode = EOACompassMode.rotated
        let compassMode = EOACompassMode(rawValue: Int(settings.compassMode.get(appMode)))
        compassRow.key = "compass"
        compassRow.cellType = OAValueTableViewCell.reuseIdentifier
        compassRow.title = localizedString("map_widget_compass")
        compassRow.descr = OACompassMode.getTitle(compassMode ?? defaultCompassMode) ?? ""
        compassRow.accessibilityLabel = compassRow.title
        compassRow.accessibilityValue = compassRow.descr
        compassRow.iconTintColor = compassMode != .hidden ? iconTintColor : UIColor.iconColorDefault
        compassRow.iconName = OACompassMode.getIconName(compassMode ?? defaultCompassMode)

        let map3dModeRow = buttonsSection.createNewRow()
        let map3dMode = settings.map3dMode.get(appMode)
        map3dModeRow.key = "map_3d_mode"
        map3dModeRow.cellType = OAValueTableViewCell.reuseIdentifier
        map3dModeRow.title = localizedString("map_3d_mode_action")
        map3dModeRow.descr = OAMap3DModeVisibility.getTitle(map3dMode) ?? ""
        map3dModeRow.accessibilityLabel = map3dModeRow.title
        map3dModeRow.accessibilityValue = map3dModeRow.descr
        map3dModeRow.iconTintColor = map3dMode != .hidden ? iconTintColor : UIColor.iconColorDefault
        map3dModeRow.iconName = OAMap3DModeVisibility.getIconName(map3dMode)
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.descriptionVisibility(false)
            cell.valueLabel.text = item.descr
            cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
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
        } else if data.key == "map_3d_mode" {
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

    // MARK: WidgetStateDelegate

    func onWidgetStateChanged() {
        onSettingsChanged()
    }

    // MARK: OACopyProfileBottomSheetDelegate

    func onCopyProfileCompleted() {
    }

    func onCopyProfile(_ fromAppMode: OAApplicationMode) {
        settings.compassMode.set(settings.compassMode.get(fromAppMode), mode: appMode)
        settings.map3dMode.set(settings.map3dMode.get(fromAppMode), mode: appMode)
        onSettingsChanged()
    }
}
