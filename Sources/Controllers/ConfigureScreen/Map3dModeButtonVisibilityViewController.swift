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
    
    private var compassMode: EOAMap3DModeVisibility {
        get {
            OAAppSettings.sharedManager()!.map3dMode.get()
        } set {
            OAAppSettings.sharedManager()!.map3dMode.set(EOAMap3DModeVisibility(rawValue: Int(newValue.rawValue))!)
        }
    }
    
    override func generateData() {
        let section = tableData.createNewSection()
        section.footerText = localizedString("map_3d_mode_hint")
        for i in 0 ..< 3 {
            let row = section.createNewRow()
            let visibilityMode = EOAMap3DModeVisibility(rawValue: i)!
            let title = OAMap3DModeVisibility.getTitle(visibilityMode) ?? ""
            let descr = OAMap3DModeVisibility.getDescription(visibilityMode)
            row.setObj(NSNumber(value: i), forKey: "map_3d_mode")
            row.title = title
            row.descr = descr
            row.iconName = OAMap3DModeVisibility.getIconName(visibilityMode)
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
            cell?.tintColor = UIColor(rgb: Int(color_primary_purple))
        }
        if let cell = cell {
            let isSelected = compassMode == EOAMap3DModeVisibility(rawValue: (item.obj(forKey: "map_3d_mode") as! NSNumber).intValue)
            cell.descriptionLabel.text = item.descr
            cell.descriptionVisibility(item.descr?.count ?? 0 > 0)
            cell.titleLabel.text = item.title
            cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
            cell.leftIconView.tintColor = UIColor(rgb: (isSelected ? Int(OAAppSettings.sharedManager()!.applicationMode.get().getIconColor()) : Int(color_tint_gray)))
            cell.accessoryType = isSelected ? .checkmark : .none
            cell.accessibilityValue = localizedString(isSelected ? "shared_string_selected" : "shared_string_not_selected")
        }
        return cell
    }
    
    override func getTitle() -> String! {
        localizedString("map_3d_mode_action")
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        localizedString("shared_string_close")
    }
    
    override func getTableHeaderDescription() -> String! {
        localizedString("map_3d_mode_description")
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func isNavbarSeparatorVisible() -> Bool {
        false
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        compassMode = EOAMap3DModeVisibility(rawValue: (item.obj(forKey: "map_3d_mode") as! NSNumber).intValue)!
        delegate?.onWidgetStateChanged()
        self.dismiss()
    }
    
}

