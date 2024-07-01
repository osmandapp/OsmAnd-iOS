//
//  DownloadingCellMultipleResourceHelper.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 12/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class DownloadingCellMultipleResourceHelper: DownloadingCellResourceHelper, OADownloadMultipleResourceDelegate {
    
    private var multipleDownloadingItems = [OAMultipleResourceSwiftItem]()
    
    // MARK: - Resource methods
    
    override func getResource(_ resourceId: String) -> OAResourceSwiftItem? {
        var item = super.getResource(resourceId)
        if item is OAMultipleResourceSwiftItem {
            item = getActiveItemFrom(resourceItem: item, useDefautValue: true)
        }
        return item
    }
    
    override func isInstalled(_ resourceId: String) -> Bool {
        let item = super.getResource(resourceId)
        if let multipleItem = item as? OAMultipleResourceSwiftItem {
            for subitem in multipleItem.items() {
                if subitem.isInstalled() {
                    return true
                }
            }
        }
        return super.isInstalled(resourceId)
    }
    
    override func isDownloading(_ resourceId: String) -> Bool {
        var item = super.getResource(resourceId)
        if item is OAMultipleResourceSwiftItem {
            item = getActiveItemFrom(resourceItem: item, useDefautValue: true)
        }
        if let item {
            return item.downloadTask() != nil
        }
        return super.isDownloading(resourceId)
    }
    
    func getResourceId(_ multipleItem: OAMultipleResourceSwiftItem) -> String? {
        multipleItem.getResourceId()
    }
    
    private func refreshMultipleDownloadTasks() {
        for resourceId in getAllResourceIds() {
            let item = super.getResource(resourceId)
            if let multipleItem = item as? OAMultipleResourceSwiftItem {
                for subitem in multipleItem.items() {
                    subitem.refreshDownloadTask()
                }
            }
        }
    }
    
    // OAMultipleResourceItem is using for Contour lines. It have two OAResourceItem subitems - for feet and for meters file.
    // This method return currently downloading subitem. Or just the first one.
    private func getActiveItemFrom(resourceItem: OAResourceSwiftItem?, useDefautValue: Bool) -> OAResourceSwiftItem? {
        if let resourceItem, let multipleItem = resourceItem as? OAMultipleResourceSwiftItem {
            return multipleItem.getActiveItem(useDefautValue)
        }
        return nil
    }
    
    // MARK: - Cell setup methods
    
    override func getOrCreateCell(_ resourceId: String, swiftResourceItem: OAResourceSwiftItem?) -> DownloadingCell? {
        guard let multipleItem = swiftResourceItem as? OAMultipleResourceSwiftItem else { return nil }
        for subitem in multipleItem.items() {
            subitem.refreshDownloadTask()
        }
        
        if super.getResource(resourceId) == nil {
            // Saving OAMultipleResourceItem here. Not OAResourceItem subitem.
            saveResource(resource: multipleItem, resourceId: resourceId)
            
            let downloadingSubitem = getActiveItemFrom(resourceItem: multipleItem, useDefautValue: true)
            if downloadingSubitem != nil && downloadingSubitem?.downloadTask() != nil {
                saveStatus(resourceId: resourceId, status: .inProgress)
            }
        }
        return super.getOrCreateCell(resourceId)
    }
    
    override func onCellClicked(_ resourceId: String) {
        guard let multipleItem = super.getResource(resourceId) as? OAMultipleResourceSwiftItem else { return }
        
        if !isInstalled(resourceId) || isAlwaysClickable {
            if !isDownloading(resourceId) {
                if let hostViewController, let vc = OADownloadMultipleResourceViewController(swiftResource: multipleItem) {
                    vc.delegate = self
                    let navController = UINavigationController(rootViewController: vc)
                    hostViewController.present(navController, animated: true)
                }
            } else {
                if let downloadingItem = getActiveItemFrom(resourceItem: multipleItem, useDefautValue: false) {
                    stopDownload(downloadingItem.resourceId())
                }
            }
        }
    }
    
    // MARK: - OADownloadMultipleResourceDelegate
    
    func downloadResources(_ item: OAMultipleResourceSwiftItem, selectedItems: [OAResourceSwiftItem]) {
        OAResourcesUISwiftHelper.offerMultipleDownloadAndInstall(of: item, selectedItems: selectedItems, onTaskCreated: { [weak self] _ in
            guard let self else { return }
            self.refreshMultipleDownloadTasks()
            if let hostTableView = self.getHostTableView() {
                hostTableView.reloadData()
            }
        }, onTaskResumed: nil)
    }
    
    func checkAndDeleteOtherSRTMResources(_ itemsToCheck: [OAResourceSwiftItem]) {
        OAResourcesUISwiftHelper .checkAndDeleteOtherSRTMResources(itemsToCheck)
    }
    
    func clearMultipleResources() {
        multipleDownloadingItems = [OAMultipleResourceSwiftItem]()
    }
    
    func onDetailsSelected(_ item: OAResourceSwiftItem) {
    }
}
