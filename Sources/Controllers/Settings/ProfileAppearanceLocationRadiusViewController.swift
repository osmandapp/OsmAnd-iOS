//
//  ProfileAppearanceLocationRadiusViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 04/09/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAProfileAppearanceLocationRadiusUpdatable)
protocol ProfileAppearanceLocationRadiusUpdatable: AnyObject {
    func onLocationRadiusUpdated(newValue: Int)
}

@objc(OAProfileAppearanceLocationRadiusViewController)
@objcMembers
final class ProfileAppearanceLocationRadiusViewController: OABaseNavbarViewController {
   
    private static let isSelectedKey = "isSelectedKey"
    private static let rawValueKey = "rawValueKey"
    
    var selectedIndex = 0
    weak var delegate: ProfileAppearanceLocationRadiusUpdatable?
    
    override func getTitle() -> String {
        localizedString("location_radius")
    }
    
    override func getTableHeaderDescription() -> String {
        localizedString("location_radius_description")
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        let section = tableData.createNewSection()
        
        let values = MarkerDisplayOption.allValues()
        
        for i in 0 ..< values.count {
            let value = values[i]
            let isSelected = i == selectedIndex
            let row = section.createNewRow()
            row.cellType = OASimpleTableViewCell.reuseIdentifier
            row.key = value.nameId
            row.title = value.name()
            row.iconName = isSelected ? "ic_checkmark_default" : nil
            row.setObj(isSelected, forKey: Self.isSelectedKey)
            row.setObj(value.rawValue, forKey: Self.rawValueKey)
        }
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
            cell.leftIconVisibility(true)
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            if item.bool(forKey: Self.isSelectedKey) {
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
                cell.leftIconView.tintColor = UIColor.iconColorActive
            } else {
                cell.leftIconView = nil
            }
            return cell
        }
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        let selectedRawValue = item.integer(forKey: Self.rawValueKey)
        if let delegate {
            delegate.onLocationRadiusUpdated(newValue: selectedRawValue)
        }
        dismiss()
    }
}
