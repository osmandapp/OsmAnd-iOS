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

        let quickActionsCount = OAQuickActionRegistry.sharedInstance().getQuickActionsCount()
        let quickActionsEnabled = settings.quickActionIsOn.get()
        let actionsString = quickActionsEnabled ? String(quickActionsCount) : localizedString("shared_string_off")
        let quickActionRow = buttonsSection.createNewRow()
        quickActionRow.title = localizedString("configure_screen_quick_action")
        quickActionRow.descr = quickActionsEnabled ? String(format: localizedString("ltr_or_rtl_combine_via_colon"),
                                                            localizedString("shared_string_actions"),
                                                            actionsString) : actionsString
        quickActionRow.iconTintColor = quickActionsEnabled ? UIColor(rgb: Int(appMode.getIconColor())) : UIColor.iconColorDefault
        quickActionRow.key = "quickAction"
        quickActionRow.iconName = "ic_custom_quick_action"
        quickActionRow.cellType = OAValueTableViewCell.reuseIdentifier
        quickActionRow.accessibilityLabel = quickActionRow.title
        quickActionRow.accessibilityValue = quickActionRow.descr
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
        if data.key == "quickAction" {
            let vc = OAQuickActionListViewController()
            vc?.delegate = self
            show(vc)
        }
    }

    // MARK: Selectors

    override func onRightNavbarButtonPressed() {
        let alert = UIAlertController(title: localizedString("add_button"), message: localizedString("enter_new_name"), preferredStyle: .alert)
        alert.addTextField()

        let saveAction = UIAlertAction(title: localizedString("shared_string_save"), style: .default) { [weak self] _ in
            guard let self else { return }
            if let buttonName = alert.textFields?.first?.text {
                
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
