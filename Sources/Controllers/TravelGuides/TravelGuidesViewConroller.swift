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
    
    //MARK: Data
    
    override func getTitle() -> String! {
        localizedString("shared_string_travel_guides")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        let button = createRightNavbarButton(localizedString("shared_string_options"), iconName: nil, action: #selector(onOptionsButtonClicked), menu: nil)
        button?.accessibilityLabel = localizedString("shared_string_options")
        return [button!]
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        let downloadSection = tableData.createNewSection()
        
        let downloadHeaderRow = downloadSection.createNewRow()
        downloadHeaderRow.cellType = OARightIconTableViewCell.getIdentifier()
        downloadHeaderRow.title = localizedString("download_file")
        downloadHeaderRow.iconName = "ic_custom_import"
        downloadHeaderRow.setObj(NSNumber(booleanLiteral: true), forKey: "kHideSeparator")
        
        let downloadDescrRow = downloadSection.createNewRow()
        downloadDescrRow.cellType = OARightIconTableViewCell.getIdentifier()
        downloadDescrRow.descr = localizedString("travel_card_download_descr")
        downloadDescrRow.setObj(NSNumber(booleanLiteral: false), forKey: "kHideSeparator")
        
        var downloadingResouces = OAResourcesUISwiftHelper.getResourcesInRepositoryIds(byRegionId: "travel", resourceTypeNames: ["travel"])
        downloadingResouces?.sort(by: { a, b in
            a.title() < b.title()
        })
        for resource in downloadingResouces! {
            let row = downloadSection.createNewRow()
            row.cellType = "kDownloadCellKey"
            row.title = resource.title()
            row.descr = resource.type() + "  •  " + resource.formatedSize()
            row.iconTint = resource.isInstalled() ? Int(color_primary_purple) : Int(color_tint_gray)
            if let icon = resource.icon() {
                row.setObj(icon, forKey: "kIconKey")
            }
            row.setObj(NSNumber(booleanLiteral: resource.isInstalled()), forKey: "kIsInstalledKey")
        }
        
    }


    //MARK: Actions
    
    func onOptionsButtonClicked() {
        print("onOptionsButtonClicked")
    }
    
    func onRowItemClicked(indexPath: IndexPath) {
        print("onRowItemClicked")
    }
    
    func accessoryButtonPressed(button: UIControl , event: UIEvent) {
        if let touches = event.touches(for: button) {
            if touches.count > 0 {
                let point = touches.first!.location(in: self.tableView)
                if let indexPath = self.tableView.indexPathForRow(at: point) {
                    self.tableView.delegate?.tableView?(self.tableView, accessoryButtonTappedForRowWith: indexPath)
                }
            }
        }
    }


    //MARK: TableView

    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        
        if item.cellType == "kDownloadCellKey" {
            var cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "kDownloadCellKey")
            
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
        } else if item.cellType == OARightIconTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OARightIconTableViewCell.getIdentifier()) as? OARightIconTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OARightIconTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OARightIconTableViewCell
                cell?.selectionStyle = .none
                cell?.leftIconVisibility(false)
            }
            if let cell {
                if let title = item.title {
                    cell.titleLabel.text = title
                    cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
                    cell.titleVisibility(true)
                } else {
                    cell.titleVisibility(false)
                }
                
                if let descr = item.descr {
                    cell.descriptionLabel.text = descr
                    cell.descriptionLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    cell.descriptionVisibility(true)
                } else {
                    cell.descriptionVisibility(false)
                }
                
                if let iconName = item.iconName {
                    cell.rightIconView.image = UIImage.templateImageNamed(iconName)
                    cell.rightIconVisibility(true)
                } else {
                    cell.rightIconVisibility(false)
                }
                
                let hideSeparator = item.bool(forKey: "kHideSeparator")
                if hideSeparator {
                    cell.separatorInset = UIEdgeInsets(top: 0, left: CGFloat.greatestFiniteMagnitude, bottom: 0, right: 0)
                    
                } else {
                    cell.separatorInset = .zero
                }
            }
            
            outCell = cell
        }
        
        return outCell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        onRowItemClicked(indexPath: indexPath)
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        onRowItemClicked(indexPath: indexPath)
    }

}
