//
//  DownloadingCellCloudHelper.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 12/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class DownloadingCellCloudHelper: DownloadingCellBaseHelper {
    
    private var resourceIcons = [String: String]()
    
    override init() {
        super.init()
        resourceIcons = [String: String]()
        NotificationCenter.default.addObserver(self, selector: #selector(onBackupItemStarted), name: Notification.Name(kBackupItemStartedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onBackupItemProgress), name: Notification.Name(kBackupItemProgressNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onBackupProgressItemFinished), name: Notification.Name(kBackupItemFinishedNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func helperHasItemFor(_ resourceId: String) -> Bool {
        resourceIcons[resourceId] != nil
    }
    
    func getAllResourceIds() -> [String] {
        Array(resourceIcons.keys)
    }
    
    
    func saveResourceIcon(iconName: String, resourceId: String) {
        resourceIcons[resourceId] = iconName
    }
    
    // MARK: - Resource methods
    
    func getResourceId(typeName: String, filename: String) -> String {
        typeName.appending(filename)
    }
    
    override func getLeftIconName(_ resourceId: String) -> String? {
        if let resourceItem = resourceIcons[resourceId] {
            return resourceItem
        }
        return nil
    }
    
    // MARK: - Downloading cell progress observer's methods
    
    @objc private func onBackupItemStarted(notification: NSNotification) {
        guard let type = notification.userInfo?["type"] as? String, 
              let name = notification.userInfo?["name"] as? String else { return }
        let resourceId = getResourceId(typeName: type, filename: name)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if helperHasItemFor(resourceId) {
                setCellProgress(resourceId: resourceId, progress: 0, status: .started)
            }
        }
    }
    
    @objc private func onBackupItemProgress(notification: NSNotification) {
        guard let type = notification.userInfo?["type"] as? String,
              let name = notification.userInfo?["name"] as? String,
              let value = notification.userInfo?["value"] as? Float else { return }
        let resourceId = getResourceId(typeName: type, filename: name)
        let progress = value / 100
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if helperHasItemFor(resourceId) {
                setCellProgress(resourceId: resourceId, progress: progress, status: .inProgress)
            }
        }
    }
    
    @objc private func onBackupProgressItemFinished(notification: NSNotification) {
        guard let type = notification.userInfo?["type"] as? String,
              let name = notification.userInfo?["name"] as? String else { return }
        
        let resourceId = getResourceId(typeName: type, filename: name)
    
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  helperHasItemFor(resourceId) else { return }
            
            setCellProgress(resourceId: resourceId, progress: 1, status: .finished)
            if let cell = getOrCreateCell(resourceId) {
                cell.leftIconView.tintColor = .iconColorActive
            }
        }
    }
}
