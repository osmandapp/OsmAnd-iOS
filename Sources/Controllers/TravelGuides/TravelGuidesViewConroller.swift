//
//  TravelGuidesViewConroller.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 24.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation


@objc(OATravelGuidesViewConroller)
@objcMembers
class TravelGuidesViewConroller: OABaseNavbarViewController {
    
    override func getTitle() -> String! {
        localizedString("shared_string_travel_guides")
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        let downloadSection = tableData.createNewSection()
        downloadSection.headerText = localizedString("shared_string_download")
        
        var downloadingResouces = OAResourcesUISwiftHelper.getResourcesInRepositoryIds(byRegionId: "travel", resourceTypeNames: ["travel"])
        downloadingResouces?.sort(by: { a, b in
            a.title() < b.title()
        })
        for resource in downloadingResouces! {
            let row = downloadSection.createNewRow()
            row.cellType = kDownloadCellKey
            row.title = resource.title()
            row.descr = resource.type() + "  •  " + resource.formatedSize()
            row.iconTint = resource.isInstalled() ? Int(color_primary_purple) : Int(color_tint_gray)
            if let icon = resource.icon() {
                row.setObj(icon, forKey: "kIconKey")
            }
            row.setObj(NSNumber(booleanLiteral: resource.isInstalled()), forKey: "kIsInstalledKey")
        }
        
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        
        if item.cellType == kDownloadCellKey {
            var cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: kDownloadCellKey)
            
            cell.textLabel?.text = item.title
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            
            cell.detailTextLabel?.text = item.descr
            cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
            cell.detailTextLabel?.textColor = UIColor(rgb: 0x929292)
            
            if let icon: UIImage = item.obj(forKey: "kIconKey") as? UIImage {
                cell.imageView?.image = icon
                cell.imageView?.tintColor = UIColor(rgb: item.iconTint)
            }
            
            let isInstalled = item.bool(forKey: "kIsInstalledKey")
            if (!isInstalled) {
                let iconImage = UIImage.templateImageNamed("ic_custom_download")!
                var btnAcc = UIButton(type: .system)
                btnAcc.addTarget(self, action: #selector(self.accessoryButtonPressed(button:event:)), for: .touchUpInside)
                btnAcc.setImage(iconImage, for: .normal)
                btnAcc.tintColor = UIColor(rgb: color_primary_purple)
                btnAcc.frame = CGRect(x: 0, y: 0, width: 30, height: 50)
                cell.accessoryView = btnAcc
            }
            
            outCell = cell
        }
        
        return outCell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        print("onRowSelected")
    }
    
    func accessoryButtonPressed(button: UIControl , event: UIEvent) {
        print("!!! accessoryButtonPressed")
        
//        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
//        if (!indexPath)
//            return;
//
//        [self.tableView.delegate tableView:self.tableView accessoryButtonTappedForRowWithIndexPath: indexPath];
    }
    
}
