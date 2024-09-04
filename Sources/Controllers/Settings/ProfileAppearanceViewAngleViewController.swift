//
//  ProfileAppearanceViewAngleViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 04/09/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAProfileAppearanceViewAngleViewController)
@objcMembers
final class ProfileAppearanceViewAngleViewController: OABaseNavbarViewController {
   
    private static let isSelectedKey = "isSelectedKey"
    private static let rawValueKey = "rawValueKey"
    
    private let mode: OAApplicationMode
    weak var delegate: Updatable?
    
    init(appMode: OAApplicationMode) {
        self.mode = appMode
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getTitle() -> String {
        localizedString("view_angle")
    }
    
    override func getTableHeaderDescription() -> String {
        localizedString("view_angle_description")
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        let section = tableData.createNewSection()
        
        let selectedIndex = OAAppSettings.sharedManager().viewAngleVisibility.get(mode)
        let values = MarkerDisplayOption.allValues()
        
        for value in MarkerDisplayOption.allValues() {
            let isSelected = selectedIndex == value.rawValue
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
        OAAppSettings.sharedManager().viewAngleVisibility.set(Int32(selectedRawValue), mode: mode)
        if let delegate {
            delegate.update()
        }
        dismiss()
    }
}
