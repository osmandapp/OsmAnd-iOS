//
//  CompassVisibilityViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 08.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OACompassVisibilityViewController)
@objcMembers
class CompassVisibilityViewController: OABaseNavbarViewController {
    
    weak var delegate: WidgetStateDelegate?
    
    private var compassMode: EOACompassMode {
        get {
            EOACompassMode(rawValue: Int(OAAppSettings.sharedManager()!.compassMode.get()))!
        } set {
            OAAppSettings.sharedManager()!.compassMode.set(Int32(newValue.rawValue))
        }
    }
    
    override func generateData() {
        let section = tableData.createNewSection()
        for i in 0 ..< 3 {
            let row = section.createNewRow()
            let compassMode = EOACompassMode(rawValue: i)!
            let title = OACompassMode.getTitle(compassMode) ?? ""
            let descr = OACompassMode.getDescription(compassMode)
            row.setObj(NSNumber(value: i), forKey: "compass_mode")
            row.title = title
            row.descr = descr
            row.iconName = OACompassMode.getIconName(compassMode)
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.accessibilityLabel = title
            row.accessibilityValue = descr
        }
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
        if cell == nil {
            let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
            cell = nib?.first as? OASimpleTableViewCell
            cell?.tintColor = UIColor.iconColorActive
        }
        if let cell = cell {
            let isSelected = compassMode == EOACompassMode(rawValue: (item.obj(forKey: "compass_mode") as! NSNumber).intValue)
            cell.descriptionLabel.text = item.descr
            cell.descriptionVisibility(item.descr?.count ?? 0 > 0)
            cell.titleLabel.text = item.title
            cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
            cell.leftIconView.tintColor = isSelected ? UIColor(rgb: Int(OAAppSettings.sharedManager()!.applicationMode.get().getIconColor())) : UIColor.iconColorDisabled
            cell.accessoryType = isSelected ? .checkmark : .none
            cell.accessibilityValue = localizedString(isSelected ? "shared_string_selected" : "shared_string_not_selected")
        }
        return cell
    }
    
    override func getTitle() -> String! {
        localizedString("map_widget_compass")
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        localizedString("shared_string_close")
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        compassMode = EOACompassMode(rawValue: (item.obj(forKey: "compass_mode") as! NSNumber).intValue)!
        delegate?.onWidgetStateChanged()
        self.dismiss()
    }
    
}
