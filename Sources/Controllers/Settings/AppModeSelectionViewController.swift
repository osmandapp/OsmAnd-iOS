//
//  OAAppModeSelectionViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 23.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAAppModeSelectionViewController)
@objcMembers
class AppModeSelectionViewController: OABaseNavbarViewController {
    
    var appModes: [OAApplicationMode]!
    let appMode: OAApplicationMode!
    var delegate: AppModeSelectionDelegate?
    
    init() {
        appMode = OAAppSettings.sharedManager()!.applicationMode.get()
        super.init()
    }
    
    required init?(coder: NSCoder) {
        self.appMode = nil
        super.init(coder: coder)
    }
    
    override func generateData() {
        tableData.clearAllData()
        appModes = OAApplicationMode.values()
    }
    
    override func onLeftNavbarButtonPressed() {
        if self.tableView.isEditing {
            updateProfileOrder()
            self.tableView.isEditing = false
            setupNavbarButtons()
        } else {
            super.onLeftNavbarButtonPressed()
        }
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        if self.tableView.isEditing {
            return nil
        }
        let newProfileAction = UIAction(title: localizedString("new_profile"),
                                               image: UIImage(systemName: "plus.square")) { [weak self] _ in
            guard let self = self else { return }
            
            self.dismiss(animated: true)
            self.delegate?.onNewProfilePressed()
        }

        let rearrangeAction = UIAction(title: localizedString("shared_string_rearrange"),
                                       image: UIImage(systemName: "arrow.up.and.down.text.horizontal")) { [weak self] _ in
            
            guard let self = self else { return }
            
            self.tableView.isEditing = true
            self.setupNavbarButtons()
        }

        let actionsMenu = UIMenu(title: "",
                                            image: nil,
                                            identifier: nil,
                                            options: .displayInline,
                                            children: [newProfileAction, rearrangeAction])

        
        let button = createRightNavbarButton(nil, systemIconName: "ellipsis.circle", action: nil, menu: actionsMenu)
        button?.accessibilityLabel = localizedString("shared_string_menu")
        return [button!]
    }
    
    override func getTitle() -> String! {
        localizedString("switch_profile")
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        localizedString(self.tableView.isEditing ? "shared_string_done" : "shared_string_cancel")
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let appMode = appModes![indexPath.row]
        var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
        if cell == nil {
            let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
            cell = nib?.first as? OASimpleTableViewCell
            cell?.descriptionVisibility(false)
            cell?.tintColor = UIColor.iconColorActive
        }
        if let cell = cell {
            cell.titleLabel.text = appMode.toHumanString()
            cell.leftIconView.image = UIImage.templateImageNamed(appMode.getIconName())
            cell.leftIconView.tintColor = appMode.getProfileColor()
            let selected = appMode == self.appMode
            cell.accessoryType = selected ? .checkmark : .none
            cell.accessibilityValue = localizedString(selected ? "shared_string_selected" : "shared_string_not_selected")
        }
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func rowsCount(_ section: Int) -> Int {
        appModes!.count
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        delegate?.onAppModeSelected(appModes[indexPath.row])
        dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true // Enable row reordering
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove = appModes[sourceIndexPath.row]
        appModes.remove(at: sourceIndexPath.row)
        appModes.insert(itemToMove, at: destinationIndexPath.row)
    }
    
    private func updateProfileOrder() {
        for (index, element) in appModes.enumerated() {
            element.setOrder(Int32(index))
        }
        OAApplicationMode.reorderAppModes()
    }
}

protocol AppModeSelectionDelegate {
    func onAppModeSelected(_ appMode: OAApplicationMode)
    func onNewProfilePressed()
}
