//
//  TravelGuidesSettingsDownloadViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 19/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

class TravelGuidesSettingsDownloadViewController : OABaseNavbarViewController {
    
    var delegate: Updatable?
    
    override func getTitle() -> String! {
        return localizedString("wikivoyage_download_pics")
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        let mode = OsmAndApp.swiftInstance().data.travelGuidesImagesDownloadMode
        
        let section = tableData.createNewSection()
        section.headerText = localizedString("download_images_settings_header")
        section.footerText = localizedString("download_images_settings_footer")
        
        let noneRow = section.createNewRow()
        noneRow.cellType = OASimpleTableViewCell.getIdentifier()
        noneRow.title = OADownloadMode.none().title
        noneRow.setObj((mode == OADownloadMode.none()), forKey: "isSelected")
        noneRow.key = "none"
        
        let wifiRow = section.createNewRow()
        wifiRow.cellType = OASimpleTableViewCell.getIdentifier()
        wifiRow.title = OADownloadMode.wifi_ONLY().title
        wifiRow.setObj((mode == OADownloadMode.wifi_ONLY()), forKey: "isSelected")
        wifiRow.key = "wifi"
        
        let anyRow = section.createNewRow()
        anyRow.cellType = OASimpleTableViewCell.getIdentifier()
        anyRow.title = OADownloadMode.any_NETWORK().title
        anyRow.setObj((mode == OADownloadMode.any_NETWORK()), forKey: "isSelected")
        anyRow.key = "any"
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASimpleTableViewCell
                cell?.descriptionVisibility(false)
                cell?.leftIconVisibility(false)
            }
            if let cell {
                cell.titleLabel.text = item.title
                let isSelected = item.bool(forKey: "isSelected")
                cell.accessoryType = isSelected ? .checkmark : .none
            }
            return cell
        }
        return outCell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if item.key == "none" {
            OsmAndApp.swiftInstance().data.travelGuidesImagesDownloadMode = OADownloadMode.none()
        } else if item.key == "wifi" {
            OsmAndApp.swiftInstance().data.travelGuidesImagesDownloadMode = OADownloadMode.wifi_ONLY()
        } else if item.key == "any" {
            OsmAndApp.swiftInstance().data.travelGuidesImagesDownloadMode = OADownloadMode.any_NETWORK()
        }
        
        if delegate != nil {
            delegate?.update()
        }
        dismiss()
    }
    
}
