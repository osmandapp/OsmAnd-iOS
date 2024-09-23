//
//  DownloadingListViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 19/09/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

final class DownloadingListViewController: OABaseNavbarViewController, DownloadingCellResourceHelperDelegate {
    
    private var downloadingListHelper: DownloadingListHelper?
    private var downloadingCellResourceHelper: DownloadingCellResourceHelper?
//    private var downloadingCellMultipleResourceHelper: DownloadingCellMultipleResourceHelper?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDownloadingCellHelper()
        fetchResources()
    }
    
    func setupDownloadingCellHelper() {
        weak var weakSelf = self
        downloadingListHelper = DownloadingListHelper()
        
        downloadingCellResourceHelper = DownloadingCellResourceHelper()
        downloadingCellResourceHelper?.hostViewController = weakSelf
        downloadingCellResourceHelper?.setHostTableView(weakSelf?.tableView)
        downloadingCellResourceHelper?.delegate = weakSelf
        downloadingCellResourceHelper?.stopWithAlertMessage = true
        downloadingCellResourceHelper?.isDownloadedLeftIconRecolored = true
        downloadingCellResourceHelper?.leftIconColor = .iconColorGreen
        downloadingCellResourceHelper?.rightIconStyle = .hideIconAfterDownloading
        
//        downloadingCellMultipleResourceHelper = DownloadingCellMultipleResourceHelper()
//        downloadingCellMultipleResourceHelper?.hostViewController = weakSelf
//        downloadingCellMultipleResourceHelper?.setHostTableView(weakSelf?.tableView)
//        downloadingCellMultipleResourceHelper?.delegate = weakSelf
//        downloadingCellMultipleResourceHelper?.rightIconStyle = .hideIconAfterDownloading
//        downloadingCellMultipleResourceHelper?.stopWithAlertMessage = true
        
        //TODO: delete
//        downloadingCellResourceHelper?.debugName = "DownloadingListVC - simple"
//        downloadingCellMultipleResourceHelper?.debugName = "DownloadingListVC - multiple"
    }
    
    private func fetchResources() {
        generateData()
        downloadingCellResourceHelper?.cleanCellCache()
//        downloadingCellMultipleResourceHelper?.cleanCellCache()
        tableView.reloadData()
    }
    
    override func generateData() {
        guard let tasks = downloadingListHelper?.getDownloadingTasks() else { return }
        
        let section = tableData.createNewSection()
        for task in tasks {
            if let resourceItem = OAResourcesUISwiftHelper.getResourceFrom(task) {
                let row = section.createNewRow()
                row.cellType = DownloadingCell.reuseIdentifier
                row.title = task.name
                let resourceId = task.key.replacingOccurrences(of: "resource:", with: "")
                row.setObj(resourceId, forKey: "resourceId")
                row.setObj(resourceItem, forKey: "item")
            }
        }
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == DownloadingCell.reuseIdentifier {
            let resourceId = item.string(forKey: "resourceId") ?? ""
            let resource = item.obj(forKey: "item") as? OAResourceSwiftItem
            return downloadingCellResourceHelper?.getOrCreateCell(resourceId, swiftResourceItem: resource)
        }
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if item.cellType == DownloadingCell.reuseIdentifier {
            let resourceId = item.string(forKey: "resourceId") ?? ""
            downloadingCellResourceHelper?.onCellClicked(resourceId)
        }
    }
    
    // MARK: - DownloadingCellResourceHelperDelegate
   
    func onDownldedResourceInstalled() {
        fetchResources()
    }
}
