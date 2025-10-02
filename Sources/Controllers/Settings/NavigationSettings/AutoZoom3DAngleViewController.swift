//
//  AutoZoom3DAngleViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 01.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
class AutoZoom3DAngleViewController: OABaseSettingsViewController {
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String? {
        localizedString("auto_zoom_3d_angle")
    }
    
    override func getSubtitle() -> String? {
        appMode.toHumanString()
    }
    
    override func generateData() {
        tableData.clearAllData()
        let current = Int(OAAppSettings.sharedManager().autoZoom3DAngle.get(appMode))
        let deg = localizedString("shared_string_degrees")
        let section = tableData.createNewSection()
        for angle in stride(from: 20, through: 40, by: 5) {
            let row = section.createNewRow()
            row.key = "angle_\(angle)"
            row.cellType = OASimpleTableViewCell.reuseIdentifier
            row.title = "\(angle) \(deg)"
            row.accessoryType = (angle == current) ? .checkmark : .none
            row.setObj(NSNumber(value: angle), forKey: "value")
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        guard item.cellType == OASimpleTableViewCell.reuseIdentifier else { return nil }
        let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
        cell.descriptionVisibility(false)
        cell.leftIconVisibility(false)
        cell.titleLabel.text = item.title
        cell.accessoryType = item.accessoryType
        return cell
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let row = tableData.item(for: indexPath)
        guard let angle = (row.obj(forKey: "value") as? NSNumber)?.int32Value else { return }
        OAAppSettings.sharedManager().autoZoom3DAngle.set(angle, mode: appMode)
        delegate?.onSettingsChanged()
        dismiss()
    }
}
