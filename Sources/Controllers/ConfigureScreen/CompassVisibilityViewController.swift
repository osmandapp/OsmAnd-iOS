//
//  CompassVisibilityViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 08.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class CompassVisibilityViewController: OABaseNavbarViewController {
    
    weak var delegate: WidgetStateDelegate?
    
    private var buttonState: CompassButtonState!

    // MARK: Initialize

    override func commonInit() {
        buttonState = OAMapButtonsHelper.sharedInstance().getCompassButtonState()
    }

    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }

    // MARK: Base UI

    override func getTitle() -> String {
        localizedString("map_widget_compass")
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_close")
    }

    // MARK: Table data

    override func generateData() {
        let section = tableData.createNewSection()
        for cv in CompassVisibility.allCases {
            let row = section.createNewRow()
            row.setObj(cv, forKey: "compassMode")
        }
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if let compassMode = item.obj(forKey: "compassMode") as? CompassVisibility {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
            cell.tintColor = .iconColorActive
            let isSelected = buttonState.getVisibility() == compassMode
            cell.descriptionLabel.text = compassMode.desc
            cell.descriptionVisibility(!compassMode.desc.isEmpty)
            cell.titleLabel.text = compassMode.title
            cell.leftIconView.image = UIImage.templateImageNamed(compassMode.iconName)
            cell.leftIconView.tintColor = isSelected ? UIColor(rgb: OAAppSettings.sharedManager().applicationMode.get().getIconColor()) : .iconColorDisabled
            cell.accessoryType = isSelected ? .checkmark : .none
            cell.accessibilityLabel = cell.titleLabel.text
            cell.accessibilityValue = localizedString(isSelected ? "shared_string_selected" : "shared_string_not_selected")
            return cell
        }
        return nil
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if let compassMode = item.obj(forKey: "compassMode") as? CompassVisibility {
            buttonState.visibilityPref.set(compassMode.rawValue)
            delegate?.onWidgetStateChanged()
        }
        dismiss()
    }
}
