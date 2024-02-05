//
//  CloudTrashViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 01.02.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation
import OSLog

@objc(OACloudTrashViewController)
@objcMembers
final class CloudTrashViewController: OABaseNavbarViewController, OAOnPrepareBackupListener, OAOnDeleteFilesListener {

    private static let daysForTrashClearing = 30
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CloudTrashViewController.self)
    )

    private var backupHelper: OABackupHelper!
    private var settingsHelper: OANetworkSettingsHelper!

    // MARK: - Initializing

    override func commonInit() {
        backupHelper = OABackupHelper.sharedInstance()
        settingsHelper = OANetworkSettingsHelper.sharedInstance()
    }

    override func registerNotifications() {
        addNotification(NSNotification.Name(kBackupSyncStartedNotification), selector: #selector(onBackupSyncStarted))
        addNotification(NSNotification.Name(kBackupProgressUpdateNotification), selector: #selector(onBackupProgressUpdate(notification:)))
        addNotification(NSNotification.Name(kBackupSyncFinishedNotification), selector: #selector(onBackupSyncFinished(notification:)))

    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        backupHelper.add(self)
        if shouldPrepareBackup() {
            backupHelper.prepareBackup()
        }
    }

    // MARK: - Base UI

    override func getTitle() -> String {
        localizedString("shared_string_trash")
    }

    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        [createRightNavbarButton(nil, iconName: "ic_navbar_trash", action: #selector(onRightNavbarButtonPressed), menu: nil)]
    }

    // MARK: - Table data

    override func generateData() {
        let preparing = backupHelper.isBackupPreparing()
        let groups: [String: TrashGroup] = collectTrashGroups()
        if groups.isEmpty, !preparing {
            let emptySection = tableData.createNewSection()
            let emptyRow = emptySection.createNewRow()
            emptyRow.cellType = OALargeImageTitleDescrTableViewCell.getIdentifier()
            emptyRow.key = "empty"
            emptyRow.title = localizedString("trash_is_empty")
            emptyRow.descr = String(format: localizedString("trash_is_empty_banner_desc"), Self.daysForTrashClearing)
            emptyRow.iconName = "ic_custom_remove_outlined"
            emptyRow.iconTintColor = UIColor.iconColorDefault
        } else {
            for (name, group) in groups {
                let section = tableData.createNewSection()
                section.headerText = name
                for item in group.getItems() {
                    let row = section.createNewRow()
                    row.cellType = OASimpleTableViewCell.getIdentifier()
                    row.setObj(item, forKey: "trashItem")
                }
            }
        }
    }

    private func collectTrashItems() -> [TrashItem] {
        var items: [TrashItem] = []
        if let backup: OAPrepareBackupResult = backupHelper.backup {
            let info: OABackupInfo = backup.backupInfo
            let filesToDelete: NSMutableArray = info.filesToDelete
            if filesToDelete.count > 0 {
                for file: OARemoteFile in info.filesToDelete as! [OARemoteFile] {
                    items.append(TrashItem(oldFile: file, deletedFile: nil))
                }
            }
            let oldFiles: [String: OARemoteFile] = backup.getRemoteFiles(.old)
            let deletedFiles: [String: OARemoteFile] = backup.getRemoteFiles(.deleted)
            if !oldFiles.isEmpty && !deletedFiles.isEmpty {
                for (key, file) in deletedFiles {
                    if let oldFile: OARemoteFile = oldFiles[key] {
                        items.append(TrashItem(oldFile: oldFile, deletedFile: file))
                    }
                }
            }
        }
        return items
    }

    private func collectTrashGroups() -> [String: TrashGroup] {
        var groups: [String: TrashGroup] = [:]
        var items: [TrashItem] = collectTrashItems()
        if !items.isEmpty {
            items.sort(by: { i1, i2 in
                i1.time > i2.time
            })
            
            for item in items {
                let time: Int = item.time
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "LLLL yyyy"
                let name = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(time))).capitalized

                var group: TrashGroup? = groups[name]
                if group == nil {
                    group = TrashGroup(name: name)
                    groups[name] = group
                }
                group?.addItem(item: item)
            }
        }
        return groups
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASimpleTableViewCell
                cell?.accessoryType = .disclosureIndicator
            }
            if let cell {
                if let trashItem = item.obj(forKey: "trashItem") as? TrashItem {
                    cell.titleLabel.text = trashItem.name
                    cell.titleLabel.accessibilityLabel = trashItem.name
                    cell.descriptionLabel.text = trashItem.descr
                    cell.descriptionLabel.accessibilityLabel = trashItem.descr
                    cell.leftIconView.image = trashItem.icon

                    var iconColor: UIColor
                    if let profileItem = trashItem.settingsItem as? OAProfileSettingsItem {
                        iconColor = UIColor(rgb: profileItem.appMode.getIconColor())
                    } else {
                        iconColor = UIColor.iconColorDefault
                    }
                    cell.leftIconView.tintColor = iconColor
                }
            }
            return cell
        } else if item.cellType == OALargeImageTitleDescrTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OALargeImageTitleDescrTableViewCell.getIdentifier()) as? OALargeImageTitleDescrTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OALargeImageTitleDescrTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OALargeImageTitleDescrTableViewCell
                cell?.selectionStyle = .none
                cell?.showButton(false)
            }
            if let cell {
                cell.titleLabel?.text = item.title
                cell.titleLabel?.accessibilityLabel = item.title
                cell.descriptionLabel?.text = item.descr
                cell.descriptionLabel?.accessibilityLabel = item.descr
                cell.cellImageView?.image = UIImage.templateImageNamed(item.iconName)
                cell.cellImageView?.tintColor = item.iconTintColor
            }

            if let update = cell?.needsUpdateConstraints() {
                cell?.setNeedsUpdateConstraints()
            }
            return cell
        }
        return nil
    }

    // MARK: - Selectors

    override func onRightNavbarButtonPressed() {
        let alert: UIAlertController = UIAlertController.init(title: localizedString("delete_all_items"),
                                                              message: localizedString("delete_all_items_desc"),
                                                              preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
            self?.clearTrash()
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        let popPresenter = alert.popoverPresentationController
        popPresenter?.barButtonItem = getRightNavbarButtons().first
        popPresenter?.permittedArrowDirections = UIPopoverArrowDirection.any

        present(alert, animated: true)
    }

    // MARK: - Additions

    private func shouldPrepareBackup() -> Bool {
        !settingsHelper.isBackupSyncing() && !backupHelper.isBackupPreparing() && backupHelper.backup?.backupInfo == nil
    }

    private func clearTrash() {
        var files: [OARemoteFile] = []
        for item: TrashItem in collectTrashItems() {
            files.append(contentsOf: item.remoteFiles)
        }
//        String message = app.getString(R.string.trash_is_empty);
        backupHelper.deleteFilesSync(files, byVersion: true, listener: self)
    }

    //MARK: - OAOnPrepareBackupListener

    func onBackupPreparing() {
        reloadDataWith(animated: true, completion: nil)
    }

    func onBackupPrepared(_ backupResult: OAPrepareBackupResult) {
        reloadDataWith(animated: true, completion: nil)
    }

    //MARK: - OAOnDeleteFilesListener

    func onFilesDeleteStarted(_ files: [OARemoteFile]!) {
    }

    func onFileDeleteProgress(_ file: OARemoteFile!, progress: Int) {
    }

    func onFilesDeleteDone(_ errors: [OARemoteFile : String]!) {
        if !errors.isEmpty {
            OAUtilities.showToast(localizedString("subscribe_email_error"), details: errors.values.joined(separator: ";"), duration: 4, in: view)
        } else {
            OAUtilities.showToast(localizedString("trash_is_empty"), details: nil, duration: 4, in: view)
        }
        backupHelper.prepareBackup()
    }

    func onFilesDeleteError(_ status: Int, message: String!) {
        OAUtilities.showToast(localizedString("subscribe_email_error"), details: message, duration: 4, in: view)
        backupHelper.prepareBackup()
    }

    //MARK: - OASyncBackupTask

    @objc private func onBackupSyncStarted() {
    }

    @objc private func onBackupProgressUpdate(notification: NSNotification) {
        if let value = notification.userInfo?["progress"] as? Float {
            
        }
    }

    @objc private func onBackupSyncFinished(notification: NSNotification) {
        if let error = notification.userInfo?["error"] as? String {
            OAUtilities.showToast(nil, details: error, duration: 4, in: view)
        } else if !settingsHelper.isBackupSyncing() && !backupHelper.isBackupPreparing() {
            backupHelper.prepareBackup()
        }
    }
}
