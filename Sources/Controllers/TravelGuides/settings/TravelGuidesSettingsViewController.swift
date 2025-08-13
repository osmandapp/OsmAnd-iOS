//
//  TravelGuidesSettingsViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 18/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc
protocol Updatable {
    func update()
}

final class TravelGuidesSettingsViewController : OABaseNavbarViewController, Updatable {
    
    override func getTitle() -> String! {
        return localizedString("shared_string_settings")
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        return localizedString("shared_string_close")
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        let imagesSection = tableData.createNewSection()
        imagesSection.headerText = localizedString("images")
        
        let downloadImagesRow = imagesSection.createNewRow()
        downloadImagesRow.cellType = OAValueTableViewCell.getIdentifier()
        downloadImagesRow.title = localizedString("wikivoyage_download_pics")
        downloadImagesRow.descr = OsmAndApp.swiftInstance().data.travelGuidesImagesDownloadMode.title
        downloadImagesRow.iconName = "ic_custom_photo"
        downloadImagesRow.key = "downloadImagesRow"
        
        TravelGuidesImageCacheHelper.sharedDatabase.getFormattedFileSize()
        let cacheSizeRow = imagesSection.createNewRow()
        cacheSizeRow.cellType = OAValueTableViewCell.getIdentifier()
        cacheSizeRow.title = localizedString("cache_size")
        cacheSizeRow.descr = TravelGuidesImageCacheHelper.sharedDatabase.getFormattedFileSize()
        cacheSizeRow.iconName = "ic_custom_photo"
        cacheSizeRow.key = "cacheSizeRow"
        
        let historySection = tableData.createNewSection()
        let clearHistoryRow = historySection.createNewRow()
        clearHistoryRow.cellType = OAButtonTableViewCell.getIdentifier()
        clearHistoryRow.title = localizedString("search_history")
        clearHistoryRow.descr = localizedString("shared_string_clear")
        clearHistoryRow.iconName = "ic_custom_history"
        clearHistoryRow.key = "clearHistoryRow"
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        
        if item.cellType == OAValueTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.getIdentifier()) as? OAValueTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OAValueTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OAValueTableViewCell
                cell?.accessoryType = .disclosureIndicator
                cell?.descriptionVisibility(false)
                cell?.leftIconView.tintColor = UIColor.iconColorSecondary
            }
            if let cell {
                cell.titleLabel.text = item.title
                cell.valueLabel.text = item.descr
                if let iconName = item.iconName {
                    cell.leftIconView.image = UIImage(named: iconName)
                }
            }
            outCell = cell
        } else if item.cellType == OAButtonTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.getIdentifier()) as? OAButtonTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OAButtonTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OAButtonTableViewCell
                cell?.descriptionVisibility(false)
                cell?.buttonVisibility(true)
                cell?.leftIconView.tintColor = UIColor.iconColorSecondary
            }
            if let cell {
                cell.titleLabel.text = item.title
                if let iconName = item.iconName {
                    cell.leftIconView.image = UIImage(named: iconName)
                }
                cell.button.setTitle(item.descr, for: .normal)
                cell.button.addTarget(self, action: #selector(showClearHistoryAlert), for: .touchUpInside)
            }
            outCell = cell
        }
        
        return outCell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        
        if item.key == "downloadImagesRow" {
            let vc = TravelGuidesSettingsDownloadViewController()
            vc.delegate = self
            show(vc)
        } else if item.key == "cacheSizeRow" {
            let vc = TravelGuidesSettingsCacheViewController()
            vc.delegate = self
            show(vc)
        } else if item.key == "clearHistoryRow" {
            showClearHistoryAlert()
        }
    }
    
    @objc func showClearHistoryAlert() {
        let alert = UIAlertController(title: localizedString("search_history"), message: localizedString("clear_travel_search_history"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .default))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_clear"), style: .default, handler: { [weak self] a in
            guard let self else { return }
            TravelObfHelper.shared.getBookmarksHelper().clearHistory()
            self.generateData()
            self.tableView.reloadData()
            OAUtilities.showToast(nil, details: localizedString("cleared_travel_search_history"), duration: 4, in: self.view)
        }))
        self.present(alert, animated: true)
    }
    
    
    //MARK: Updatable
    
    func update() {
        generateData()
        tableView.reloadData()
    }
    
}
