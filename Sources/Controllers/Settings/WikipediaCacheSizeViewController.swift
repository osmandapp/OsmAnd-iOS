//
//  WikipediaCacheSizeViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 31/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//


import Foundation

@objc(OAWikipediaCacheSizeViewController)
@objcMembers
final class WikipediaCacheSizeViewController : OABaseNavbarViewController {
    
    var delegate: WikipediaScreenDelegate?
    var cacheHelper: WikiImageCacheHelper?
    
    override func getTitle() -> String! {
        return localizedString("wikivoyage_download_pics")
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        return localizedString("shared_string_cancel")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cacheHelper = WikiImageCacheHelper()
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        let infoSection = tableData.createNewSection()
        let cacheSizeRow = infoSection.createNewRow()
        cacheSizeRow.cellType = OAValueTableViewCell.getIdentifier()
        cacheSizeRow.title = localizedString("cache_size")
        cacheSizeRow.descr = cacheHelper?.getFormattedFileSize()
        cacheSizeRow.iconName = "ic_custom_photo"
        cacheSizeRow.key = "cacheSizeRow"
        
        let buttonSection = tableData.createNewSection()
        let buttonRow = buttonSection.createNewRow()
        buttonRow.cellType = OASearchMoreCell.getIdentifier()
        buttonRow.title = localizedString("remove_cache")
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
            
        } else if item.cellType == OASearchMoreCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASearchMoreCell.getIdentifier()) as? OASearchMoreCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASearchMoreCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASearchMoreCell
                cell?.textView.font = UIFont.preferredFont(forTextStyle: .body)
                cell?.textView.textColor = UIColor.buttonBgColorDisruptive
            }
            if let cell {
                cell.textView.text = item.title
            }
            outCell = cell
        }
        
        return outCell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if item.cellType == OASearchMoreCell.getIdentifier() {
            showClearCacheAlert()
        }
    }
    
    func showClearCacheAlert() {
        let alert = UIAlertController(title: localizedString("image_cache"), message: localizedString("remove_cache_alert"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .default))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_clear"), style: .default, handler: { [weak self] a in
            guard let self else { return }
            self.cacheHelper?.cleanAllData()
            if let delegate {
                delegate.updateWikipediaSettings()
            }
            self.dismiss()
        }))
        self.present(alert, animated: true)
    }
    
}
