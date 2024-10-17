//
//  DownloadingListHelper.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 19/09/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class DownloadingListHelper: NSObject, DownloadingCellResourceHelperDelegate {
    
    weak var hostDelegate: DownloadingCellResourceHelperDelegate?
    
    private var downloadsManager: OADownloadsManager
    private var allDownloadingsCell: OATitleIconProgressbarCell?
    private var downloadTaskProgressObserver: OAAutoObserverProxy?
    private var downloadTaskCompletedObserver: OAAutoObserverProxy?
    private var localResourcesChangedObserver: OAAutoObserverProxy?
    private var downloadTaskCount = 0
    
    override init() {
        downloadsManager = OsmAndApp.swiftInstance().downloadsManager
        super.init()
        downloadTaskProgressObserver = OAAutoObserverProxy(self, withHandler: #selector(onDownloadResourceTaskProgressChanged), andObserve: OsmAndApp.swiftInstance().downloadsManager.progressCompletedObservable)
        downloadTaskCompletedObserver = OAAutoObserverProxy(self, withHandler: #selector(onDownloadResourceTaskFinished), andObserve: OsmAndApp.swiftInstance().downloadsManager.completedObservable)
        localResourcesChangedObserver = OAAutoObserverProxy(self, withHandler: #selector(onLocalResourcesChanged), andObserve: OsmAndApp.swiftInstance().localResourcesChangedObservable)
    }
    
    func hasDownloads() -> Bool {
        !getDownloadingTasks().isEmpty
    }
    
    func getDownloadingTasks() -> [OADownloadTask] {
        guard let keys = downloadsManager.keysOfDownloadTasks() else { return [] }
        var tasks = [OADownloadTask]()
        for key in keys {
            if let task = downloadsManager.firstDownloadTasks(withKey: key as? String) {
                tasks.append(task)
            }
        }
        tasks.sort { $0.creationTime < $1.creationTime }  
        return tasks
    }
    
    func buildAllDownloadingsCell() -> OATitleIconProgressbarCell? {
        var cell: OATitleIconProgressbarCell?
        if let allDownloadingsCell {
            cell = allDownloadingsCell
        } else {
            let nib = Bundle.main.loadNibNamed(OATitleIconProgressbarCell.reuseIdentifier, owner: self, options: nil)
            cell = nib?.first as? OATitleIconProgressbarCell
        }
        guard let cell else { return nil }
        
        cell.accessoryType = .disclosureIndicator
        cell.imgView.image = UIImage.templateImageNamed("ic_custom_multi_download")
        cell.imgView.tintColor = .iconColorActive
        
        var title = localizedString("downloading") + ": "
        let tasks = getDownloadingTasks()
        if let downloadingTask = tasks.first(where: { $0.state == .running }) {
            title += downloadingTask.name
        }
        cell.textView.text = title
        
        cell.progressBar.setProgress(Float(calculateAllDownloadingsCellProgress()), animated: false)
        cell.progressBar.progressTintColor = .iconColorActive
        
        allDownloadingsCell = cell
        return allDownloadingsCell
    }
    
    func getListViewController() -> DownloadingListViewController {
        let vc = DownloadingListViewController()
        vc.delegate = self
        return vc
    }
    
    private func calculateAllDownloadingsCellProgress() -> Double {
        if let downloadingTask = getDownloadingTasks().first(where: { $0.state == .running }) {
            return Double(downloadingTask.progressCompleted)
        }
        return 0
    }
    
    // MARK: - Downloading cell progress observer's methods
    
    @objc private func onDownloadResourceTaskProgressChanged(observer: Any, key: Any, value: Any) {
        updateProgreesBar(animated: true)
    }
    
    @objc private func onDownloadResourceTaskFinished(observer: Any, key: Any, value: Any) {
        updateProgreesBar(animated: false)
    }
    
    @objc private func onLocalResourcesChanged(observer: Any, key: Any, value: Any) {
        updateProgreesBar(animated: false)
    }
    
    private func updateProgreesBar(animated: Bool) {
        if let allDownloadingsCell {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let newProgress = Float(self.calculateAllDownloadingsCellProgress())
                self.allDownloadingsCell?.progressBar.setProgress(newProgress , animated: animated)
                
                let newDownloadingsCount = self.getDownloadingTasks().count
                if newDownloadingsCount != self.downloadTaskCount {
                    self.downloadTaskCount = newDownloadingsCount
                    self.buildAllDownloadingsCell()
                }
            }
        }
    }
    
    // MARK: - DownloadingCellResourceHelperDelegate
   
    func onDownloadingCellResourceNeedUpdate() {
        hostDelegate?.onDownloadingCellResourceNeedUpdate()
    }
}
