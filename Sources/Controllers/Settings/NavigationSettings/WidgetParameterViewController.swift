//
//  WidgetParameterViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 26.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetParameterViewController)
@objcMembers
class WidgetParameterViewController: OABaseNavbarViewController {
    
    var screenTitle: String!
    var appMode: OAApplicationMode!
    var delegate: WidgetStateDelegate?
    
    override func getTitle() -> String! {
        screenTitle
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        if (item.cellType == OASimpleTableViewCell.getIdentifier()) {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASimpleTableViewCell
                cell?.tintColor = UIColor(rgb: Int(color_primary_purple))
            }
            if let cell = cell {
                if let imageName = item.iconName, !imageName.isEmpty {
                    cell.leftIconVisibility(true)
                    cell.leftIconView.image = UIImage(named: imageName)
                } else {
                    cell.leftIconVisibility(false)
                }
                if let descr = item.descr, !descr.isEmpty {
                    cell.descriptionVisibility(true)
                    cell.descriptionLabel.text = descr
                } else {
                    cell.descriptionVisibility(false)
                }
                
                let pref = item.obj(forKey: "pref") as! OACommonPreference
                let selectedVal = pref.toStringValue(appMode)
                let val = stringValue(from: item.obj(forKey: "value"), pref: pref)
                cell.accessoryType = selectedVal == val ? .checkmark : .none
                cell.titleLabel.text = item.title
                
            }
            return cell
        }
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        let pref = item.obj(forKey: "pref") as! OACommonPreference
        let val = stringValue(from: item.obj(forKey: "value"), pref: pref)
        pref.setValueFrom(val, appMode: appMode)
        
        delegate?.onWidgetStateChanged()
        dismiss()
    }
    
    private func stringValue(from value: Any?, pref: OACommonPreference) -> String {
        if let stringValue = value as? String {
            // If the value is already a String, return it
            return stringValue
        } else if let numberValue = value as? NSNumber {
            return numberValue.stringValue
        } else {
            // Convert the value to a String using its description
            return String(describing: value)
        }
    }
    
}
