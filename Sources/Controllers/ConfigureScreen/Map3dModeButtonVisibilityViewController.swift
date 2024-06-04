//
//  Map3dModeButtonVisibilityViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 30.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAMap3dModeButtonVisibilityViewController)
@objcMembers
class Map3dModeButtonVisibilityViewController: OABaseNavbarViewController {

    weak var delegate: WidgetStateDelegate?

    private var buttonState: Map3DButtonState!

    // MARK: Initialize

    override func commonInit() {
        buttonState = OAMapButtonsHelper.sharedInstance().getMap3DButtonState()
    }

    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }

    // MARK: Base UI

    override func getTitle() -> String {
        localizedString("map_3d_mode_action")
    }

    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_close")
    }

    // MARK: Table data

    override func generateData() {
        let section = tableData.createNewSection()
        section.footerText = localizedString("map_3d_mode_hint")
        for m3dv in Map3DModeVisibility.allCases {
            let row = section.createNewRow()
            row.setObj(m3dv, forKey: "map3dMode")
        }
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if let map3dMode = item.obj(forKey: "map3dMode") as? Map3DModeVisibility {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
            cell.tintColor = UIColor.iconColorActive
            cell.descriptionVisibility(false)
            let isSelected = buttonState.getVisibility() == map3dMode
            cell.titleLabel.text = map3dMode.title
            cell.leftIconView.image = UIImage.templateImageNamed(map3dMode.iconName)
            cell.leftIconView.tintColor = isSelected ? UIColor(rgb: OAAppSettings.sharedManager().applicationMode.get().getIconColor()) : UIColor.iconColorDisabled
            cell.accessoryType = isSelected ? .checkmark : .none
            cell.accessibilityLabel = cell.titleLabel.text
            cell.accessibilityValue = localizedString(isSelected ? "shared_string_selected" : "shared_string_not_selected")
            return cell
        }
        return nil
    }

    override func getTableHeaderDescription() -> String {
        localizedString("map_3d_mode_description")
    }

    override func hideFirstHeader() -> Bool {
        true
    }

    override func isNavbarSeparatorVisible() -> Bool {
        false
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if let map3dMode = item.obj(forKey: "map3dMode") as? Map3DModeVisibility {
            buttonState.visibilityPref.set(map3dMode.rawValue)
            delegate?.onWidgetStateChanged()
        }
        self.dismiss()
    }
}
