//
//  DownloadingListViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 19/09/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

final class DownloadingListViewController: OABaseNavbarViewController, DownloadingCellResourceHelperDelegate {
    
    weak var delegate: DownloadingCellResourceHelperDelegate?
    
    private var downloadingListHelper: DownloadingListHelper?
    private var downloadingCellResourceHelper: DownloadingCellResourceHelper?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDownloadingCellHelper()
        generateData()
    }
    
    override func getTitle() -> String! {
        localizedString("downloading")
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_close")
    }
    
    func setupDownloadingCellHelper() {
        downloadingListHelper = DownloadingListHelper()
        
        downloadingCellResourceHelper = DownloadingCellResourceHelper()
        downloadingCellResourceHelper?.hostViewController = self
        downloadingCellResourceHelper?.setHostTableView(self.tableView)
        downloadingCellResourceHelper?.delegate = self
        downloadingCellResourceHelper?.stopWithAlertMessage = true
        downloadingCellResourceHelper?.isDownloadedLeftIconRecolored = true
        downloadingCellResourceHelper?.rightIconStyle = .showDoneIconAfterDownloading
        downloadingCellResourceHelper?.rightIconName = "ic_custom_done"
        downloadingCellResourceHelper?.rightIconColor = .iconColorActive
        downloadingCellResourceHelper?.showDownloadingBytesInDescription = true
    }
    
    private func fetchResources() {
        DispatchQueue.main.async { [weak self] in
            self?.downloadingCellResourceHelper?.cleanCellCache()
            self?.tableView.reloadData()
        }
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
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == DownloadingCell.reuseIdentifier {
            if let downloadingCellResourceHelper {
                let resourceId = item.string(forKey: "resourceId") ?? ""
                let resource = item.obj(forKey: "item") as? OAResourceSwiftItem
                let cell = downloadingCellResourceHelper.getOrCreateCell(resourceId, swiftResourceItem: resource)
                if downloadingCellResourceHelper.isFinished(resourceId) {
                    cell?.leftIconView.tintColor = .iconColorActive
                    cell?.rightIconView.image = UIImage.templateImageNamed(downloadingCellResourceHelper.rightIconName)
                    cell?.rightIconVisibility(true)
                } else {
                    cell?.leftIconView.tintColor = .iconColorDefault
                    cell?.rightIconView.image = nil
                    cell?.rightIconVisibility(false)
                }
                return cell
            }
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
   
    func onDownloadingCellResourceNeedUpdate() {
        fetchResources()
        delegate?.onDownloadingCellResourceNeedUpdate()
    }
}
