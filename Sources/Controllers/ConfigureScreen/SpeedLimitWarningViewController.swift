//
//  SpeedLimitWarningViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 21/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

final class SpeedLimitWarningViewController: OABaseNavbarViewController {
    
    weak var delegate: WidgetStateDelegate?
    
    override func generateData() {
        let isAlwaysRowSelected = OAAppSettings.sharedManager().showSpeedLimitWarning.get() == .always
        
        let section = tableData.createNewSection()
        
        let alwaysRow = section.createNewRow()
        alwaysRow.cellType = OASimpleTableViewCell.reuseIdentifier
        alwaysRow.title = OACommonSpeedLimitWarningState.toHumanString(.always)
        alwaysRow.setObj(isAlwaysRowSelected, forKey: "isSelected")
        alwaysRow.accessibilityLabel = title
        
        let whenExceededRow = section.createNewRow()
        whenExceededRow.cellType = OASimpleTableViewCell.reuseIdentifier
        whenExceededRow.title = OACommonSpeedLimitWarningState.toHumanString(.whenExceeded)
        whenExceededRow.setObj(!isAlwaysRowSelected, forKey: "isSelected")
        whenExceededRow.accessibilityLabel = title
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as! OASimpleTableViewCell
        cell.tintColor = .iconColorActive
        cell.descriptionVisibility(false)
        cell.leftIconVisibility(false)
        let isSelected = item.bool(forKey: "isSelected")
        cell.titleLabel.text = item.title
        cell.accessoryType = isSelected ? .checkmark : .none
        cell.accessibilityValue = localizedString(isSelected ? "shared_string_selected" : "shared_string_not_selected")
        return cell
    }
    
    override func getTitle() -> String! {
        localizedString("speed_limit_warning")
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        localizedString("shared_string_close")
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        OAAppSettings.sharedManager().showSpeedLimitWarning.set(indexPath.row == 0 ? .always : .whenExceeded)
        delegate?.onWidgetStateChanged()
        dismiss()
    }
}
