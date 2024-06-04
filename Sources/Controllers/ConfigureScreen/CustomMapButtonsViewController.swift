//
//  CustomMapButtonsViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 19.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

class CustomMapButtonsViewController: OABaseNavbarViewController, WidgetStateDelegate {

    weak var delegate: MapButtonsDelegate?
    private var appMode: OAApplicationMode!
    private var settings: OAAppSettings!
    private var mapButtonsHelper: OAMapButtonsHelper!

    // MARK: Initialization

    override func commonInit() {
        settings = OAAppSettings.sharedManager()
        appMode = settings.applicationMode.get()
        mapButtonsHelper = OAMapButtonsHelper.sharedInstance()
    }

    override func registerCells() {
        addCell(OAValueTableViewCell.reuseIdentifier)
    }

    // MARK: Base UI

    override func getTitle() -> String {
        localizedString("custom_buttons")
    }

    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        return [createRightNavbarButton(nil,
                                        iconName: "ic_navbar_add",
                                        action: #selector(onRightNavbarButtonPressed),
                                        menu: nil)]
    }

    // MARK: Table data

    override func generateData() {
        tableData.clearAllData()

        let buttonsSection = tableData.createNewSection()
        for mapButtonState in mapButtonsHelper.getButtonsStates() {
            let enabled = mapButtonState.isEnabled()
            let quickActionRow = buttonsSection.createNewRow()
            quickActionRow.key = mapButtonState.id
            quickActionRow.cellType = OAValueTableViewCell.reuseIdentifier
            quickActionRow.setObj(mapButtonState, forKey: "buttonState")
            quickActionRow.iconTintColor = enabled ? UIColor(rgb: Int(appMode.getIconColor())) : UIColor.iconColorDefault
            quickActionRow.descr = localizedString(enabled ? "shared_string_on" : "shared_string_off")
            quickActionRow.accessibilityLabel = quickActionRow.title
            quickActionRow.accessibilityValue = quickActionRow.descr
        }
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == OAValueTableViewCell.reuseIdentifier, let buttonState = item.obj(forKey: "buttonState") as? QuickActionButtonState {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.descriptionVisibility(false)
            cell.leftIconView.image = buttonState.getIcon()
            cell.leftIconView.tintColor = item.iconTintColor
            cell.titleLabel.text = buttonState.getName()
            cell.valueLabel.text = item.descr
            cell.accessibilityLabel = item.accessibilityLabel
            cell.accessibilityValue = item.accessibilityValue
            return cell
        }
        return nil
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if let buttonState = item.obj(forKey: "buttonState") as? QuickActionButtonState {
            if let vc = OAQuickActionListViewController(buttonState: buttonState) {
                vc.delegate = self
                vc.quickActionUpdateCallback = { [weak self] in
                    self?.onSettingsChanged()
                }
                show(vc)
            }
        }
    }

    // MARK: Selectors

    override func onRightNavbarButtonPressed() {
        let alert = UIAlertController(title: localizedString("add_button"), message: localizedString("enter_new_name"), preferredStyle: .alert)
        alert.addTextField()

        let saveAction = UIAlertAction(title: localizedString("shared_string_save"), style: .default) { [weak self] _ in
            guard let self else { return }
            if let name = alert.textFields?.first?.text {
                if name.isEmpty {
                    OAUtilities.showToast(localizedString("empty_name"), details: nil, duration: 4, in: view)
                } else if !mapButtonsHelper.isActionButtonNameUnique(name) {
                    OAUtilities.showToast(localizedString("custom_map_button_name_present"), details: nil, duration: 4, in: view)
                } else {
                    let buttonState = mapButtonsHelper.createNewButtonState()
                    buttonState.setName(name)
                    mapButtonsHelper.add(buttonState)
                    onSettingsChanged()
                }
            }
        }
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))

        alert.preferredAction = saveAction
        present(alert, animated: true)
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
}
