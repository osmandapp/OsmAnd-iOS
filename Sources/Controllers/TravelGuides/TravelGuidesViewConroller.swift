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
    
    var downloadingCellHelper: OADownloadingCellHelper = OADownloadingCellHelper()
    var dataLock: NSObject = NSObject()
    var downloadingResources: [OAResourceSwiftItem] = []

    override func viewDidLoad() {
        setupDownloadingCellHelper()
        super.viewDidLoad()
    }

    func setupDownloadingCellHelper() {
        downloadingCellHelper = OADownloadingCellHelper()
        downloadingCellHelper.hostViewController = self
        downloadingCellHelper.hostTableView = self.tableView
        downloadingCellHelper.hostDataLock = dataLock
        weak var weakself = self
        
        downloadingCellHelper.fetchResourcesBlock = {
            var downloadingResouces = OAResourcesUISwiftHelper.getResourcesInRepositoryIds(byRegionId: "travel", resourceTypeNames: ["travel"])
            if (downloadingResouces != nil) {
                downloadingResouces!.sort(by: { a, b in
                    a.title() < b.title()
                })
                weakself!.downloadingResources = downloadingResouces!
            }
        }
        
        downloadingCellHelper.getSwiftResourceByIndexBlock = { (indexPath: IndexPath?) -> OAResourceSwiftItem? in
            
            let headerCellsCountInResourcesSection = weakself!.headerCellsCountInResourcesSection()
            if (indexPath != nil && indexPath!.row >= headerCellsCountInResourcesSection) {
                return weakself!.downloadingResources[indexPath!.row - headerCellsCountInResourcesSection]
            }
            return nil
        }
        
        downloadingCellHelper.getTableDataModelBlock = {
            return weakself!.tableData
        }
    }
    
    
    //MARK: Data
    
    override func getTitle() -> String! {
        localizedString("shared_string_travel_guides")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        let button = createRightNavbarButton(localizedString("shared_string_options"), iconName: nil, action: #selector(onOptionsButtonClicked), menu: nil)
        button?.accessibilityLabel = localizedString("shared_string_options")
        return [button!]
    }
    
    func headerCellsCountInResourcesSection() -> Int {
        return 2
    }
    
    override func generateData() {
        downloadingCellHelper.fetchResourcesBlock()
        
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
        
        for _ in downloadingResources {
            let row = downloadSection.createNewRow()
            row.cellType = "kDownloadCellKey"
        }
    }

    func foobar() {
        let task = LoadWikivoyageDataAsyncTask(resetData: true)
        task.execute()
    }
    

    //MARK: Actions
    
    func onOptionsButtonClicked() {
        print("onOptionsButtonClicked")
        
        
        foobar()
    }

    //MARK: TableView

    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        
        if item.cellType == "kDownloadCellKey" {
            let resource = downloadingCellHelper.getSwiftResourceByIndexBlock(indexPath)
            outCell = downloadingCellHelper.setupSwiftCell(resource, indexPath: indexPath)
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
        downloadingCellHelper.onItemClicked(indexPath)
    }

}


class LoadWikivoyageDataAsyncTask {
    //var vc.delegate
    var travelHelper: TravelObfHelper
    var resetData: Bool
    
    init (resetData: Bool) {
        travelHelper = TravelObfHelper.shared;
        self.resetData = resetData
    }
    
    func execute() {
        DispatchQueue.global(qos: .default).async {
            self.doInBackground()
            DispatchQueue.main.async {
                self.onPostExecute()
            }
        }
    }
    
    func doInBackground() {
        travelHelper.initializeDataToDisplay(resetData: resetData)
    }
    
    func onPostExecute() {
        //TODO: vc.delegate.reloadData()
    }
}
