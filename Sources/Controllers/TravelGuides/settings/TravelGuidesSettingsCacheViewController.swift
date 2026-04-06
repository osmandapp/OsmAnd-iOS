//
//  TravelGuidesSettingsCacheViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 30/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class TravelGuidesSettingsCacheViewController: OABaseNavbarViewController {
    
    weak var delegate: Updatable?
    
    override func getTitle() -> String {
        return localizedString("cache_size")
    }
    
    override func registerCells() {
        addCell(OAValueTableViewCell.reuseIdentifier)
        addCell(OASearchMoreCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        let infoSection = tableData.createNewSection()
        let cacheSizeRow = infoSection.createNewRow()
        cacheSizeRow.cellType = OAValueTableViewCell.reuseIdentifier
        cacheSizeRow.title = localizedString("cache_size")
        cacheSizeRow.descr = TravelGuidesImageCacheHelper.sharedDatabase.getFormattedFileSize()
        cacheSizeRow.iconName = "ic_custom_photo"
        cacheSizeRow.key = "cacheSizeRow"
        
        let buttonSection = tableData.createNewSection()
        let buttonRow = buttonSection.createNewRow()
        buttonRow.cellType = OASearchMoreCell.reuseIdentifier
        buttonRow.title = localizedString("remove_cache")
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == OAValueTableViewCell.reuseIdentifier, let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as? OAValueTableViewCell {
            cell.accessoryType = .disclosureIndicator
            cell.descriptionVisibility(false)
            cell.leftIconView.tintColor = UIColor.iconColorSecondary
            cell.titleLabel.text = item.title
            cell.valueLabel.text = item.descr
            if let iconName = item.iconName {
                cell.leftIconView.image = UIImage(named: iconName)
            }
            return cell
        } else if item.cellType == OASearchMoreCell.reuseIdentifier, let cell = tableView.dequeueReusableCell(withIdentifier: OASearchMoreCell.reuseIdentifier, for: indexPath) as? OASearchMoreCell {
            cell.textView.font = UIFont.preferredFont(forTextStyle: .body)
            cell.textView.textColor = UIColor.buttonBgColorDisruptive
            cell.textView.text = item.title
            return cell
        }
        
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if item.cellType == OASearchMoreCell.reuseIdentifier {
            showClearCacheAlert()
        }
    }
    
    func showClearCacheAlert() {
        let alert = UIAlertController(title: localizedString("image_cache"), message: localizedString("remove_cache_alert"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .default))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_clear"), style: .default, handler: { [weak self] _ in
            guard let self else { return }
            TravelGuidesImageCacheHelper.sharedDatabase.cleanAllData()
            if let delegate {
                delegate.update()
            }
            self.dismiss()
        }))
        
        self.present(alert, animated: true)
    }
}
